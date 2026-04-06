;;; fetch-file.el --- Download files from an Org task list with template support  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Your Name
;; Author: Your Name <your@email.com>
;; Keywords: files, hypermedia, org
;; Version: 1.5
;; Package-Requires: ((emacs "26.1") (org "9.0") (stpl "2.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; `fetch-file' helps you manage file downloads using an Org file as a task list.
;; It supports `stpl' template syntax ({{...}} and {%...%}) in URL, PATH and DESC fields.
;; Templates are rendered at download time using a configurable environment.
;;
;; To use templates, install `stpl.el' (provided separately) and set
;; `fetch-file-template-env' to an alist of variable bindings.
;;
;; Example Org entry:
;;
;;   * My file
;;     :PROPERTIES:
;;     :URL:      https://example.com/{{ (user-login-name) }}.zip
;;     :PATH:     ~/Downloads/{% (format "%s-%s" name date) %}
;;     :DESC:     Download for {{ name }}
;;     :END:
;;
;; Usage:
;;   (setq fetch-file-template-env '((name . "Alice") (date . "2026-01-01")))
;;   (fetch-file-download-all)   ; uses default org file ~/Downloads/fetch-file-tasks.org
;;   (fetch-file-download-task "My file")

;;; Code:

(require 'org)
(require 'url)
(require 'cl-lib)

(declare-function stpl-render-with-env "stpl" (str env))
(declare-function stpl-render "stpl" (str))

;;; User options

(defgroup fetch-file nil
  "Download files from an Org task list."
  :group 'files
  :prefix "fetch-file-")

(defcustom fetch-file-org-file "~/Downloads/fetch-file-tasks.org"
  "Path to the Org file containing download tasks.
Default is ~/Downloads/fetch-file-tasks.org.  If the file does not exist,
it will be created automatically with example tasks."
  :type 'file
  :group 'fetch-file)

(defcustom fetch-file-overwrite nil
  "If non-nil, overwrite existing local files."
  :type 'boolean
  :group 'fetch-file)

(defcustom fetch-file-verbose t
  "If non-nil, print progress messages."
  :type 'boolean
  :group 'fetch-file)

(defcustom fetch-file-template-env nil
  "Alist of environment variables for `stpl' template engine.
Example: '((name . \"Alice\") (greeting . \"Hello\"))"
  :type '(alist :key-type symbol :value-type sexp)
  :group 'fetch-file)

;;; Internal functions

(defun fetch-file--message (format-string &rest args)
  "Display a message if `fetch-file-verbose' is non-nil."
  (when fetch-file-verbose
    (apply #'message format-string args)))

(defun fetch-file--expand-path (path)
  "Expand PATH, handling ~ and environment variables.
PATH should already be rendered (no templates)."
  (expand-file-name (substitute-in-file-name path)))

(defun fetch-file--render-field (field)
  "Render FIELD (a string) using `stpl' with `fetch-file-template-env'.
If `stpl' is not available, return FIELD unchanged and warn."
  (if (and (stringp field) (string-match-p "{{.*}}\\|{%.*%}" field))
      (if (require 'stpl nil t)
          (let ((rendered (stpl-render-with-env field fetch-file-template-env)))
            (fetch-file--message "Rendered: %s -> %s" field rendered)
            rendered)
        (fetch-file--message "Warning: stpl not loaded, template %s not rendered" field)
        field)
    field))

(defun fetch-file--ensure-org-file ()
  "Ensure `fetch-file-org-file' exists, creating it with a template if necessary."
  (let ((file (fetch-file--expand-path fetch-file-org-file)))
    (unless (file-exists-p file)
      (let ((dir (file-name-directory file)))
        (unless (file-exists-p dir)
          (make-directory dir t)))
      (with-temp-file file
        (insert "#+TITLE: fetch-file download tasks\n")
        (insert "# This file is managed by `fetch-file'.\n")
        (insert "# Edit with `M-x fetch-file-edit` or manually.\n")
        (insert "# Template syntax: {{ lisp-expr }} and {% sub-template %} are supported.\n")
        (insert "#\n")
        (insert "# Example tasks (uncomment to use):\n")
        (insert "#\n")
        (insert "* Example group\n")
        (insert "** Simple download\n")
        (insert "   - url :: https://httpbin.org/get\n")
        (insert "   - path :: ~/Downloads/example.json\n")
        (insert "   - desc :: A sample API response\n")
        (insert "\n")
        (insert "** Template example\n")
        (insert "   - url :: https://example.com/{{ (user-login-name) }}.zip\n")
        (insert "   - path :: ~/Downloads/{% (format \"%s-%s\" name (format-time-string \"%Y%m%d\")) %}\n")
        (insert "   - desc :: Download for {{ name }}\n")
        (insert "\n"))
      (fetch-file--message "Created default task file: %s" file))))

(defun fetch-file--read-org-tasks ()
  "Parse `fetch-file-org-file' and return a list of tasks.
Each task is a plist with keys :name, :url, :path, :desc, :group.
Fields are returned as they appear in the Org file (unrendered)."
  (fetch-file--ensure-org-file)
  (let ((file (fetch-file--expand-path fetch-file-org-file))
        (tasks nil)
        (current-group nil))
    (with-temp-buffer
      (insert-file-contents file)
      (org-mode)
      (org-element-map (org-element-parse-buffer) 'headline
        (lambda (headline)
          (let* ((level (org-element-property :level headline))
                 (name (org-element-property :raw-value headline))
                 (props (org-element-property :PROPERTIES headline))
                 (url (cdr (assoc "URL" props)))
                 (path (cdr (assoc "PATH" props)))
                 (desc (cdr (assoc "DESC" props))))
            (cond
             ((= level 1)
              (setq current-group name))
             ((= level 2)
              (when (and url path)
                (push (list :name name
                            :url url
                            :path path
                            :desc (or desc "")
                            :group current-group)
                      tasks)))))))
      (nreverse tasks))))

(defun fetch-file--download-one (task)
  "Download a single TASK (plist).
Renders :url, :path, :desc using `fetch-file-template-env' before downloading."
  (let* ((name (plist-get task :name))
         (url-template (plist-get task :url))
         (path-template (plist-get task :path))
         (desc-template (plist-get task :desc))
         (url (fetch-file--render-field url-template))
         (dest (fetch-file--render-field path-template))
         (desc (fetch-file--render-field desc-template))
         (dest-expanded (fetch-file--expand-path dest))
         (dest-dir (file-name-directory dest-expanded)))
    (fetch-file--message "Downloading: %s" name)
    (when (and desc (not (string-empty-p desc)))
      (fetch-file--message "  Description: %s" desc))
    (fetch-file--message "  URL (rendered): %s" url)
    (fetch-file--message "  Destination (rendered): %s" dest-expanded)

    (unless (file-exists-p dest-dir)
      (make-directory dest-dir t))

    (when (and (file-exists-p dest-expanded) (not fetch-file-overwrite))
      (fetch-file--message "  File already exists, skipping (set `fetch-file-overwrite' to t to overwrite)")
      (cl-return-from fetch-file--download-one nil))

    (condition-case err
        (url-copy-file url dest-expanded t)
      (error
       (fetch-file--message "  Download failed: %s" (error-message-string err))
       (cl-return-from fetch-file--download-one nil)))

    (fetch-file--message "  Download complete")
    t))

;;; Edit buffer support

(defvar fetch-file--edit-buffer "*Fetch File Edit*"
  "Buffer name for editing download tasks.")

(defun fetch-file--generate-edit-content (tasks)
  "Generate a human‑editable buffer content from TASKS.
If TASKS is empty, return a template with example tasks."
  (if (null tasks)
      (concat
       "# Edit download tasks.  Modify, add, or delete entries.\n"
       "# - Each task is a level-2 headline under an optional level-1 group.\n"
       "# - Properties are written as `- key :: value' under the headline.\n"
       "# - Required keys: url, path.  Optional: desc.\n"
       "# - Template syntax: {{ lisp-expr }} and {% sub-template %} are supported.\n"
       "# - Press C-c C-c when done, C-c C-k to cancel.\n\n"
       "* Example group\n"
       "** Simple download\n"
       "   - url :: https://httpbin.org/get\n"
       "   - path :: ~/Downloads/example.json\n"
       "   - desc :: A sample API response\n\n"
       "** Template example\n"
       "   - url :: https://example.com/{{ (user-login-name) }}.zip\n"
       "   - path :: ~/Downloads/{% (format \"%s-%s\" name (format-time-string \"%Y%m%d\")) %}\n"
       "   - desc :: Download for {{ name }}\n\n"
       "# Delete the example tasks above and add your own.\n")
    (let ((groups (make-hash-table :test 'equal))
          (ungrouped-tasks nil))
      (dolist (task tasks)
        (let ((group (plist-get task :group)))
          (if group
              (push task (gethash group groups))
            (push task ungrouped-tasks))))
      (with-temp-buffer
        (insert "# Edit download tasks.  Modify, add, or delete entries.\n")
        (insert "# - Press C-c C-c when done, C-c C-k to cancel.\n\n")
        (maphash (lambda (group tasks)
                   (insert "* " group "\n")
                   (dolist (task (reverse tasks))
                     (insert "** " (plist-get task :name) "\n")
                     (insert "   - url :: " (plist-get task :url) "\n")
                     (insert "   - path :: " (plist-get task :path) "\n")
                     (let ((desc (plist-get task :desc)))
                       (when (and desc (not (string-empty-p desc)))
                         (insert "   - desc :: " desc "\n")))
                     (insert "\n"))
                   (insert "\n"))
                 groups)
        (dolist (task (reverse ungrouped-tasks))
          (insert "* " (plist-get task :name) "\n")
          (insert "   - url :: " (plist-get task :url) "\n")
          (insert "   - path :: " (plist-get task :path) "\n")
          (let ((desc (plist-get task :desc)))
            (when (and desc (not (string-empty-p desc)))
              (insert "   - desc :: " desc "\n")))
          (insert "\n"))
        (buffer-string)))))

(defun fetch-file--parse-edit-buffer ()
  "Parse current edit buffer and return a list of tasks.
Expects format:
  * GROUP (optional)
  ** TASK-NAME
     - url :: <url>
     - path :: <path>
     - desc :: <desc> (optional)"
  (goto-char (point-min))
  (let ((tasks nil)
        (current-group nil)
        (current-task nil)
        (current-props nil)
        (line nil))
    (while (not (eobp))
      (setq line (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
      (cond
       ;; 跳过注释行和空行
       ((string-match-p "\\`[[:space:]]*$" line)
        (forward-line 1))
       ((string-match-p "\\`[[:space:]]*#" line)
        (forward-line 1))
       
       ;; 一级标题：* GROUP
       ((string-match "\\`\\*+[[:space:]]+\\(.+\\)" line)
        (let* ((match (string-match "\\`\\*+\\([[:space:]]+\\)" line))
               (level (if match (length (match-string 0 line)) 1)) ; 简化：计算星号数量
               (heading (match-string 1 line)))
          ;; 更准确计算星号数量
          (setq level (string-match "\\`\\*+" line)
                level (if level (length (match-string 0 line)) 0))
          (cond
           ((= level 1)
            (when current-task
              (push (append current-task (list :group current-group)) tasks)
              (setq current-task nil current-props nil))
            (setq current-group heading
                  current-task nil
                  current-props nil))
           ((= level 2)
            (when current-task
              (push (append current-task (list :group current-group)) tasks))
            (setq current-task (list :name heading)
                  current-props nil))
           (t
            (error "Invalid headline level %d at line: %s" level line))))
        (forward-line 1))
       
       ;; 属性行：- key :: value   (允许前导空格)
       ((string-match "^[[:space:]]*-[[:space:]]+\\([a-zA-Z]+\\)[[:space:]]*::[[:space:]]*\\(.*\\)$" line)
        (let ((key (downcase (match-string 1 line)))
              (val (match-string 2 line)))
          (cond
           ((string= key "url")
            (setq current-props (plist-put current-props :url val)))
           ((string= key "path")
            (setq current-props (plist-put current-props :path val)))
           ((string= key "desc")
            (setq current-props (plist-put current-props :desc val)))
           (t
            (message "Ignoring unknown key: %s" key))))
        (forward-line 1))
       
       (t
        (error "Unexpected line format: %s" line))))
    
    ;; 保存最后一个任务
    (when current-task
      (push (append current-task current-props (list :group current-group)) tasks))
    
    ;; 验证每个任务都有 url 和 path
    (dolist (task tasks)
      (unless (and (plist-get task :url) (plist-get task :path))
        (error "Task '%s' missing required :url or :path" (plist-get task :name))))
    
    (nreverse tasks)))

(defun fetch-file--write-org-file (tasks)
  "Write TASKS back to `fetch-file-org-file' in Org format."
  (let ((file (fetch-file--expand-path fetch-file-org-file)))
    (with-temp-file file
      (insert "#+TITLE: Download tasks\n")
      (insert "# This file is managed by `fetch-file'.\n")
      (insert "# Edit using `fetch-file-edit'.\n\n")
      (let ((groups (make-hash-table :test 'equal))
            (ungrouped nil))
        (dolist (task tasks)
          (let ((group (plist-get task :group)))
            (if group
                (push task (gethash group groups))
              (push task ungrouped))))
        (maphash (lambda (group tasks)
                   (insert "* " group "\n")
                   (dolist (task (reverse tasks))
                     (insert "** " (plist-get task :name) "\n")
                     (insert "   :PROPERTIES:\n")
                     (insert "   :URL:  " (plist-get task :url) "\n")
                     (insert "   :PATH: " (plist-get task :path) "\n")
                     (let ((desc (plist-get task :desc)))
                       (when (and desc (not (string-empty-p desc)))
                         (insert "   :DESC: " desc "\n")))
                     (insert "   :END:\n\n"))
                   (insert "\n"))
                 groups)
        (dolist (task (reverse ungrouped))
          (insert "* " (plist-get task :name) "\n")
          (insert "  :PROPERTIES:\n")
          (insert "  :URL:  " (plist-get task :url) "\n")
          (insert "  :PATH: " (plist-get task :path) "\n")
          (let ((desc (plist-get task :desc)))
            (when (and desc (not (string-empty-p desc)))
              (insert "  :DESC: " desc "\n")))
          (insert "  :END:\n\n"))))))

(defun fetch-file--edit-finish ()
  "Save the edited tasks back to the Org file and close the buffer."
  (interactive)
  (condition-case err
      (let ((new-tasks (fetch-file--parse-edit-buffer)))
        (fetch-file--write-org-file new-tasks)
        (kill-buffer fetch-file--edit-buffer)
        (message "Tasks saved to %s" fetch-file-org-file))
    (error
     (message "Error saving tasks: %s" (error-message-string err))
     (message "Please fix the buffer format and try again.")
     (beep))))

(defun fetch-file--edit-cancel ()
  "Cancel editing, discard changes, and close the buffer."
  (interactive)
  (kill-buffer fetch-file--edit-buffer)
  (message "Edit cancelled."))

;;; Public API

;;;###autoload
(defun fetch-file-list-tasks ()
  "Display a list of all task names from the Org file."
  (interactive)
  (let ((tasks (fetch-file--read-org-tasks)))
    (if (null tasks)
        (message "No tasks found in %s" fetch-file-org-file)
      (message "Tasks:")
      (dolist (task tasks)
        (message "  %s" (plist-get task :name))))))

;;;###autoload
(defun fetch-file-download-all ()
  "Download all tasks defined in the Org file.
Templates in URL, PATH, DESC are rendered using `fetch-file-template-env'."
  (interactive)
  (let ((tasks (fetch-file--read-org-tasks)))
    (if (null tasks)
        (message "No tasks found in %s" fetch-file-org-file)
      (fetch-file--message "Found %d task(s)" (length tasks))
      (let ((success-count 0)
            (fail-count 0))
        (dolist (task tasks)
          (if (fetch-file--download-one task)
              (cl-incf success-count)
            (cl-incf fail-count)))
        (fetch-file--message "Done: %d succeeded, %d failed" success-count fail-count)))))

;;;###autoload
(defun fetch-file-download-task (task-name)
  "Download a single task identified by TASK-NAME.
Templates are rendered using `fetch-file-template-env'."
  (interactive "sTask name: ")
  (let ((tasks (fetch-file--read-org-tasks))
        (target nil))
    (dolist (task tasks)
      (when (string-equal (plist-get task :name) task-name)
        (setq target task)))
    (if target
        (fetch-file--download-one target)
      (error "Task '%s' not found in %s" task-name fetch-file-org-file))))

;;;###autoload
(defun fetch-file-edit ()
  "Open a dedicated buffer to edit download tasks.
Templates can be written in the fields and will be rendered at download time."
  (interactive)
  (fetch-file--ensure-org-file)
  (let ((tasks (fetch-file--read-org-tasks)))
    (with-current-buffer (get-buffer-create fetch-file--edit-buffer)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (fetch-file--generate-edit-content tasks))
        (org-mode)
        (use-local-map (copy-keymap org-mode-map))
        (local-set-key (kbd "C-c C-c") #'fetch-file--edit-finish)
        (local-set-key (kbd "C-c C-k") #'fetch-file--edit-cancel)
        (goto-char (point-min))
        (pop-to-buffer (current-buffer))))))

(provide 'fetch-file)

;;; fetch-file.el ends here
