;;; org-room.el --- A lightweight note-taking system for Org-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Your Name

;; Author: Your Name <you@example.com>
;; Keywords: org, notes, hypermedia
;; Package-Requires: ((emacs "27.1") (org "9.4"))
;; Version: 0.8.1

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

;; org-room is a simple, file‑based note‑taking system for Org‑mode.
;; It provides bidirectional links, backlinks, quick note creation,
;; and tag support without requiring an external database.
;;
;; Notes are stored in `org-room-directory'. Each note file is named
;; with a timestamp prefix and contains a `#+title:' keyword that
;; serves as the node identifier. Additionally, each note gets a
;; unique `:ID:' property to avoid title collisions and support
;; future migrations. Tags can be added via `#+filetags:' or `:TAGS:'
;; property.
;;
;; To enable convenient keybindings, activate `org-room-mode':
;;
;;   (add-hook 'org-mode-hook #'org-room-mode)
;;
;; The default bindings are:
;;
;;   C-c n f   org-room-find
;;   C-c n i   org-room-insert-link
;;   C-c n b   org-room-show-backlinks
;;   C-c n t   org-room-list-tags
;;   C-c n T   org-room-find-by-tag
;;   C-c n a   org-room-insert-tag
;;   C-c n r   org-room-rename-title
;;   C-c n u   org-room-update-cache
;;   C-c n c   org-room-cleanup-cache

;;; Code:

(require 'org)
(require 'org-room-cache)
(require 'org-room-link)
(require 'org-room-ui)

(defgroup org-room nil
  "Org-room: personal note system."
  :group 'org)

(defcustom org-room-directory (expand-file-name "~/org-room/")
  "Directory where notes are stored."
  :type 'directory
  :set (lambda (symbol value)
         (set-default symbol value)
         (when (fboundp 'org-room--initialize)
           (org-room--initialize))))

;;;###autoload
(defun org-room-initialize ()
  "Initialize org-room: ensure directory exists, scan notes and set up hooks."
  (interactive)
  (org-room--initialize))

(defun org-room--ensure-directory ()
  "Ensure `org-room-directory' exists; create it if necessary."
  (unless (file-directory-p org-room-directory)
    (make-directory org-room-directory t)))

(defun org-room--initialize ()
  "Internal: ensure directory exists, scan directory and enable hooks."
  (org-room--ensure-directory)
  (org-room-cache-scan-directory)
  (add-hook 'after-save-hook #'org-room--on-save)
  (add-hook 'org-mode-hook #'org-room--setup-link-follow)
  (message "org-room initialized"))

(defun org-room--on-save ()
  "Update cache after saving a file in `org-room-directory'."
  (when (and buffer-file-name
             (file-in-directory-p buffer-file-name org-room-directory))
    (org-room-cache-update-file buffer-file-name)))

(defun org-room--setup-link-follow ()
  "Make org-room handle [[note]] links in Org buffers."
  (add-hook 'org-open-at-point-functions #'org-room-follow-link nil t))

(defun org-room--sanitize-title (title)
  "Replace characters unsafe for filenames in TITLE."
  (replace-regexp-in-string "[^a-zA-Z0-9-]" "-" title))

(defun org-room--generate-uuid ()
  "Generate a unique ID string using `org-id-new' or fallback."
  (if (fboundp 'org-id-new)
      (org-id-new)
    ;; Fallback: use md5 of random+time
    (let ((random-str (format "%s%s%s" (current-time-string) (user-real-login-name) (random))))
      (md5 random-str))))

(defun org-room--make-title-unique (title)
  "Return a version of TITLE that does not exist in current cache.
If TITLE already exists, append \" (2)\", \" (3)\", etc."
  (let ((existing (org-room-cache-get-all-nodes))
        (new-title title)
        (counter 2))
    (while (member new-title existing)
      (setq new-title (format "%s (%d)" title counter)
            counter (1+ counter)))
    new-title))

;;;###autoload
(defun org-room-find (node)
  "Find or create note named NODE.
If note exists, open it; otherwise create a new file with a
timestamp prefix, a unique title (with automatic suffix if needed),
and insert a :PROPERTIES: block (with :ID:) followed by a #+title: line."
  (interactive
   (progn
     (org-room-cache-cleanup)           ; clean up before completing
     (list (completing-read "Note: " (org-room-cache-get-all-nodes)))))
  (org-room--ensure-directory)
  (let ((file (org-room-cache-get-file node)))
    (if file
        (find-file file)
      ;; Create new note, ensuring title uniqueness
      (let* ((unique-title (org-room--make-title-unique node))
             (timestamp (format-time-string "%Y-%m-%d-%H-%M-%S"))
             (safe-title (org-room--sanitize-title unique-title))
             (filename (concat timestamp "-" safe-title ".org"))
             (full-path (expand-file-name filename org-room-directory))
             (uuid (org-room--generate-uuid)))
        (find-file full-path)
        ;; Insert PROPERTIES block first, then #+title
        (insert ":PROPERTIES:\n")
        (insert (format ":ID:       %s\n" uuid))
        (insert ":END:\n")
        (insert (format "#+title: %s\n" unique-title))
        (save-buffer)
        ;; Update cache immediately after creation
        (org-room-cache-update-file full-path)
        (message "Created new note: %s" unique-title)))))

;;;###autoload
(defun org-room-cleanup-cache ()
  "Remove cache entries for notes whose files have been deleted."
  (interactive)
  (org-room-cache-cleanup)
  (message "Cache cleaned up"))

;;;###autoload
(defun org-room-update-cache ()
  "Force a full rescan of the note directory."
  (interactive)
  (org-room-cache-scan-directory)
  (message "Cache updated"))

;;; Tag commands

;;;###autoload
(defun org-room-list-tags ()
  "Display all tags with their counts in a dedicated buffer."
  (interactive)
  (let ((tag-index (org-room-cache-get-tag-index)))
    (with-output-to-temp-buffer "*org-room tags*"
      (with-current-buffer "*org-room tags*"
        (org-mode)
        (erase-buffer)
        (insert "Tags in org-room:\n\n")
        (dolist (entry tag-index)
          (let ((tag (car entry))
                (nodes (cdr entry)))
            (insert (format "- %s (%d)\n" tag (length nodes)))))
        (goto-char (point-min))
        (org-fold-reveal)))))

;;;###autoload
(defun org-room-find-by-tag (tag)
  "Find notes that have TAG.
Interactively, prompt for tag with completion."
  (interactive
   (let ((tags (mapcar #'car (org-room-cache-get-tag-index))))
     (if (null tags)
         (user-error "No tags found in any note")
       (list (completing-read "Tag: " tags)))))
  (let ((nodes (org-room-cache-get-nodes-by-tag tag)))
    (if (null nodes)
        (message "No notes with tag '%s'" tag)
      (let ((buffer-name (format "*org-room notes with tag %s*" tag)))
        (with-output-to-temp-buffer buffer-name
          (with-current-buffer buffer-name
            (org-mode)
            (erase-buffer)
            (insert (format "Notes with tag [[%s]]:\n\n" tag))
            (dolist (node nodes)
              (insert (format "- [[%s]]\n" node)))
            (goto-char (point-min))
            (org-fold-reveal)))))))

;;;###autoload
(defun org-room-insert-tag (&optional tag)
  "Add TAG to the current note.
If TAG is not provided, prompt for it.
This function adds the tag to the `#+filetags:' line or creates one.
If the file already has a `#+filetags:' line, it appends to it.
Otherwise, it inserts a new line after the #+title."
  (interactive
   (list (completing-read "Tag to add: " nil)))
  (unless (buffer-file-name)
    (user-error "Current buffer is not visiting a file"))
  (unless (file-in-directory-p (buffer-file-name) org-room-directory)
    (user-error "Current file is not in org-room directory"))
  (save-excursion
    (goto-char (point-min))
    (let ((case-fold-search t))
      (if (re-search-forward "^#\\+filetags:" nil t)
          ;; Append to existing line
          (let ((line-start (match-beginning 0)))
            (end-of-line)
            (insert (format ":%s" tag)))
        ;; No #+filetags: line; find #+title line
        (goto-char (point-min))
        (if (re-search-forward "^#\\+title:" nil t)
            (progn
              (end-of-line)
              (insert "\n#+filetags: " tag))
          ;; If no #+title either, just insert at top
          (insert "#+filetags: " tag "\n"))))
    (save-buffer)
    ;; Update cache after modification
    (org-room-cache-update-file (buffer-file-name))
    (message "Tag '%s' added to current note" tag)))

;;; Rename title

;;;###autoload
(defun org-room-rename-title (new-title)
  "Rename current note's title and corresponding file.
Prompts for a new title, ensures uniqueness, updates #+title line,
renames the file (preserving timestamp prefix), and updates cache.
Note: Links from other notes pointing to the old title will not be
automatically updated; you may need to fix them manually."
  (interactive
   (list (let* ((current-title (org-room--extract-current-title))
                (prompt (if current-title
                            (format "New title (current: %s): " current-title)
                          "New title: ")))
           (read-string prompt current-title))))
  (unless (buffer-file-name)
    (user-error "Current buffer is not visiting a file"))
  (unless (file-in-directory-p (buffer-file-name) org-room-directory)
    (user-error "Current file is not in org-room directory"))

  (let* ((old-path (buffer-file-name))
         (old-title (org-room--extract-current-title))
         (new-title-unique (org-room--make-title-unique new-title))
         (safe-title (org-room--sanitize-title new-title-unique))
         (old-filename (file-name-base old-path))
         (timestamp (org-room--extract-timestamp-from-filename old-filename))
         (new-filename (if timestamp
                           (concat timestamp "-" safe-title ".org")
                         ;; If no timestamp found, just use new title
                         (concat safe-title ".org")))
         (new-path (expand-file-name new-filename org-room-directory)))

    ;; Check if new file already exists (should not, due to title uniqueness)
    (when (file-exists-p new-path)
      (user-error "File %s already exists" new-filename))

    ;; Update #+title in file
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward "^#\\+title:\\s-+\\(.*\\)" nil t)
          (replace-match (format "#+title: %s" new-title-unique) nil nil nil 0)
        ;; If no #+title line, insert one at top
        (goto-char (point-min))
        (insert (format "#+title: %s\n" new-title-unique))))

    ;; Save the buffer before renaming file
    (save-buffer)

    ;; Rename file
    (rename-file old-path new-path t)

    ;; Update buffer's visited file name
    (set-visited-file-name new-path t)

    ;; Update cache
    (org-room--update-cache-after-rename old-title new-title-unique new-path)

    (message "Renamed title to '%s' and file to %s"
             new-title-unique (file-name-nondirectory new-path))))

(defun org-room--extract-timestamp-from-filename (filename)
  "Extract timestamp prefix from FILENAME (e.g., \"2026-04-01-12-34-56-notes\").
Returns timestamp string (YYYY-MM-DD-HH-MM-SS) if it matches the format,
otherwise returns nil."
  (when (string-match "^\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}-[0-9]\\{2\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)-" filename)
    (match-string 1 filename)))

(defun org-room--extract-current-title ()
  "Return the current #+title value from the current buffer."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^#\\+title:\\s-+\\(.*\\)" nil t)
        (match-string-no-properties 1)
      (file-name-base (buffer-file-name)))))

(defun org-room--update-cache-after-rename (old-title new-title new-file)
  "Update cache after renaming OLD-TITLE to NEW-TITLE, with file NEW-FILE.
Removes old title entries, then updates cache for the new file."
  ;; Remove old title from all caches
  (setq org-room-cache--nodes
        (assoc-delete-all old-title org-room-cache--nodes))
  (setq org-room-cache--links
        (assoc-delete-all old-title org-room-cache--links))
  (setq org-room-cache--tags
        (assoc-delete-all old-title org-room-cache--tags))
  ;; Also remove any backlinks that referred to the old title
  (setq org-room-cache--backlinks
        (assoc-delete-all old-title org-room-cache--backlinks))

  ;; Now add new file to cache (this will rebuild all indexes)
  (org-room-cache-update-file new-file))

;;; Keybindings and minor mode

(defvar org-room-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c n f") #'org-room-find)
    (define-key map (kbd "C-c n i") #'org-room-insert-link)
    (define-key map (kbd "C-c n b") #'org-room-show-backlinks)
    (define-key map (kbd "C-c n t") #'org-room-list-tags)
    (define-key map (kbd "C-c n T") #'org-room-find-by-tag)
    (define-key map (kbd "C-c n a") #'org-room-insert-tag)
    (define-key map (kbd "C-c n r") #'org-room-rename-title)
    (define-key map (kbd "C-c n u") #'org-room-update-cache)
    (define-key map (kbd "C-c n c") #'org-room-cleanup-cache)
    map)
  "Keymap for `org-room-mode'.")

;;;###autoload
(define-minor-mode org-room-mode
  "Minor mode for org-room keybindings and features."
  :lighter " Org-Room"
  :keymap org-room-mode-map
  (if org-room-mode
      (message "org-room mode enabled")
    (message "org-room mode disabled")))

(provide 'org-room)

;;; org-room.el ends here
