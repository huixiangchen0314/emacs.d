;;; init-utils.el --- Utility functions for Emacs configuration -*- lexical-binding: t; -*-
;;; Commentary:
;; Utility functions for Emacs initialization.  All functions are prefixed
;; with "my/util/" or "my/i/" to avoid name clashes.
;; - my/util/: general utility functions that may be used across files.
;; - my/i/: interactive commands intended for user invocation.
;;; Code:

(require 'package)

;; ------------------------------------------------------------
;; Path utilities
;; ------------------------------------------------------------

(defun my/util/add-to-load-path (dir)
  "Add DIR to `load-path'."
  (add-to-list 'load-path dir))

(defun my/util/add-to-load-path-if-exists (dir)
  "Add DIR to `load-path' if DIR exists."
  (when (file-exists-p dir)
    (my/util/add-to-load-path dir)))

;; ------------------------------------------------------------
;; Package repository management
;; ------------------------------------------------------------

(defun my/util/add-package-repo (name url)
  "Add package repository with NAME and URL to `package-archives'."
  (add-to-list 'package-archives `(,name . ,url)))

;; ------------------------------------------------------------
;; File and directory listing utilities
;; ------------------------------------------------------------

(defun my/util/list-files-in-dir (dir &optional extension)
  "Return list of regular files in DIR, optionally filtered by EXTENSION.
If EXTENSION is provided, only files ending with that extension are included.
Example: (my/util/list-files-in-dir \"/path\" \"el\")"
  (let ((pattern (if extension
                     (concat ".*\\." extension "$")
                   ".*")))
    (cl-mapcan (lambda (file)
                 (when (file-regular-p file)
                   (list file)))
               (directory-files dir t pattern))))

;; ------------------------------------------------------------
;; String/sequence utilities
;; ------------------------------------------------------------

(defun my/util/join (sequence separator &optional prefix suffix)
  "Join SEQUENCE of strings with SEPARATOR, optionally wrapping with PREFIX and SUFFIX.
If PREFIX or SUFFIX are non-nil, they are added before/after the result."
  (let ((result (mapconcat 'identity sequence separator)))
    (concat (or prefix "")
            result
            (or suffix ""))))

;; ------------------------------------------------------------
;; File renaming utilities
;; ------------------------------------------------------------

(defun my/util/rename-files (oldnames newnames)
  "Rename files from OLDNAMES to NEWNAMES sequentially.
Both arguments are lists of file paths.  The number of files must match."
  (when (and oldnames newnames)
    (rename-file (car oldnames) (car newnames) t)
    (my/util/rename-files (cdr oldnames) (cdr newnames))))

;; ------------------------------------------------------------
;; Interactive commands
;; ------------------------------------------------------------

(defun my/i/delete-this-file ()
  "Delete the current file and kill its buffer."
  (interactive)
  (unless (buffer-file-name)
    (user-error "No file is currently being edited"))
  (when (yes-or-no-p (format "Really delete '%s'?"
                             (file-name-nondirectory (buffer-file-name))))
    (delete-file (buffer-file-name))
    (kill-this-buffer)))

(defun my/i/rename-this-buffer-and-file (new-name)
  "Rename current buffer to NEW-NAME.
If buffer visits a file that exists on disk, also rename that file.
If the file does not exist, only rename the buffer and its visited
file name (without touching disk)."
  (interactive "sNew name: ")
  (let ((filename (buffer-file-name)))
    (if (and filename (file-exists-p filename))
        (progn
          (rename-file filename new-name t)
          (set-visited-file-name new-name)
          (rename-buffer new-name))
      ;; 文件不存在或 buffer 没有关联文件：只改 buffer 名字和 visited file name
      (set-visited-file-name new-name)
      (rename-buffer new-name))))

(defun my/i/browse-current-file ()
  "Open the current file in a web browser."
  (interactive)
  (let ((file-name (buffer-file-name)))
    (cond
     ((null file-name)
      (user-error "Buffer is not visiting a file"))
     ((and (fboundp 'tramp-tramp-file-p) (tramp-tramp-file-p file-name))
      (user-error "Cannot open remote file in browser"))
     (t
      (browse-url (concat "file://" file-name))))))

;; ------------------------------------------------------------
;; Provide the module
;; ------------------------------------------------------------

(provide 'init-utils)
;;; init-utils.el ends here
