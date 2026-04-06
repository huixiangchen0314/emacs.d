;;; spgit.el --- Simple Git interface for Emacs  -*- lexical-binding: t; -*-

;; Provide simple commands for common Git operations without the complexity of Magit.
;; 调用 git 命令
;; 查看 git 输出
;;; Commentary:

;;; Code:



(defgroup spgit nil
  "Simple Git interface."
  :group 'tools)

(defcustom spgit-commit-message-buffer "*spgit-commit*"
  "Buffer name for writing commit messages."
  :type 'string)

(defcustom spgit-history-limit 30
  "Number of commits to show in history view."
  :type 'integer)

(defun spgit--repository-root-path ()
  "Return the absolute path of the current Git repository root.
This function does not rely on `spgit--call-git' and uses a direct Git call."
  (with-temp-buffer
    (let ((default-directory (or (vc-root-dir) default-directory)))
      (call-process "git" nil t nil "rev-parse" "--show-toplevel")
      (goto-char (point-min))
      (buffer-substring-no-properties (point) (line-end-position)))))



(defun spgit--call-git (args)
  "Call git with ARGS in the repository root and return the output as a string."
  (let ((root (spgit--repository-root-path)))
    (unless (and root (file-directory-p (expand-file-name ".git" root)))
      (error "Not inside a Git repository"))
    (with-temp-buffer
      (let ((default-directory root))
        (apply 'call-process "git" nil t nil args))
      (buffer-string))))


(defun spgit--run (args &optional show-output)
  "Run git with ARGS. If SHOW-OUTPUT is non-nil, show output in a buffer."
  (let* ((default-directory (or (vc-root-dir) default-directory))
         (output-buffer (get-buffer-create "*spgit-output*")))
    (with-current-buffer output-buffer
      (erase-buffer)
      (apply 'call-process "git" nil t nil args))
    (when show-output
      (display-buffer output-buffer))
    (with-current-buffer output-buffer
      (buffer-string))))

(defun spgit--current-branch-name ()
  "Return the name of the current branch."
  (string-trim (spgit--call-git '("rev-parse" "--abbrev-ref" "HEAD"))))


(defun spgit--current-commit-hash ()
  "Return the full SHA-1 hash of the current HEAD commit."
  (string-trim (spgit--call-git '("rev-parse" "HEAD"))))

(defun spgit--current-commit-hash-short ()
  "Return the abbreviated (7 characters) commit hash of current HEAD."
  (string-trim (spgit--call-git '("rev-parse" "--short" "HEAD"))))

(defun spgit--current-commit-subject ()
  "Return the subject (first line) of the current commit message."
  (string-trim (spgit--call-git '("log" "-1" "--pretty=%s"))))

(defun spgit--current-commit-author ()
  "Return the author name of the current commit."
  (string-trim (spgit--call-git '("log" "-1" "--pretty=%an"))))

(defun spgit--remote-url (&optional remote-name)
  "Return the URL of the remote named REMOTE-NAME (default \"origin\")."
  (let ((remote (or remote-name "origin")))
    (string-trim (spgit--call-git `("remote" "get-url" ,remote)))))

(defun spgit--latest-tag ()
  "Return the most recent tag reachable from HEAD."
  (string-trim (spgit--call-git '("describe" "--tags" "--abbrev=0"))))

(defun spgit--commit-count ()
  "Return the total number of commits in the current branch."
  (string-to-number (string-trim (spgit--call-git '("rev-list" "--count" "HEAD")))))

(defun spgit--is-clean ()
  "Return t if working tree is clean (no uncommitted changes), nil otherwise."
  (let ((status (string-trim (spgit--call-git '("status" "--porcelain")))))
    (string-empty-p status)))

(provide 'spgit-core)

;;; spgit-core.el ends here.
