;;; spgit.el --- Simple Git interface for Emacs  -*- lexical-binding: t; -*-

;; Provide simple commands for common Git operations without the complexity of Magit.
;; 调用 git 命令
;; 查看 git 输出
;;; Code:


(require 'spgit-core)
(require 'spgit-status)
(require 'spgit-history)

(defun spgit--branch-header ()
  "Return a string with branch helper information."
  (concat
   "=== spgit branch helper ===\n"
   "Available keys: RET/SPC=switch to branch, d=delete branch, q=quit, ?=help\n"
   "============================\n\n"))

;;; Standalone commands

(defun spgit-commit ()
  "Commit staged changes, prompting for commit message."
  (interactive)
  (let ((msg (read-string "Commit message: ")))
    (spgit--run `("commit" "-m" ,msg) t)))

(defun spgit-push ()
  "Push current branch to remote."
  (interactive)
  (spgit--run '("push") t))

(defun spgit-pull ()
  "Pull from remote."
  (interactive)
  (spgit--run '("pull") t))

(defun spgit-add ()
  "Add current file to staging area."
  (interactive)
  (let ((file (buffer-file-name)))
    (if file
        (progn
          (spgit--run `("add" ,file) t)
          (message "Added %s" file))
      (message "No file associated with buffer"))))

(defun spgit-diff ()
  "Show diff for current file."
  (interactive)
  (let ((file (buffer-file-name)))
    (if file
        (spgit--run `("diff" ,file) t)
      (message "No file associated with buffer"))))

(defun spgit-log ()
  "Show git log in a buffer."
  (interactive)
  (spgit--run '("log" "--oneline" "-n" "20") t))

;;; Branch commands

(defun spgit-branch ()
  "Show branch list and allow switching/deleting branches."
  (interactive)
  (let ((buf (get-buffer-create "*spgit-branches*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert (spgit--branch-header))
      (insert (spgit--call-git '("branch")))
      (goto-char (point-min))
      (spgit-branch-mode))
    (display-buffer buf)))

(defvar spgit-branch-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'spgit-branch-switch)
    (define-key map (kbd "SPC") 'spgit-branch-switch)
    (define-key map "d" 'spgit-branch-delete)
    (define-key map "q" 'quit-window)
    (define-key map "?" 'describe-mode)
    map)
  "Keymap for `spgit-branch-mode'.")

(define-derived-mode spgit-branch-mode special-mode "SpGit-Branch"
  "Major mode for branch list.
\\{spgit-branch-mode-map}"
  (setq buffer-read-only t))

(defun spgit-branch-switch ()
  "Switch to the branch at point."
  (interactive)
  (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
    (when (string-match "^\\(?:\\* \\)?\\([^ ]+\\)" line)
      (let ((branch (match-string 1 line)))
        (spgit--run `("checkout" ,branch) t)
        (quit-window)
        (message "Switched to branch %s" branch)))))

(defun spgit-branch-delete ()
  "Delete the branch at point."
  (interactive)
  (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
    (when (string-match "^\\(?:\\* \\)?\\([^ ]+\\)" line)
      (let ((branch (match-string 1 line))
            (current (spgit--current-branch-name)))
        (if (string-equal branch current)
            (message "Cannot delete current branch")
          (when (y-or-n-p (format "Delete branch '%s'? " branch))
            (spgit--run `("branch" "-d" ,branch) t)
            (spgit-branch-refresh)))))))

(defun spgit-branch-refresh ()
  "Refresh the branch list buffer."
  (interactive)
  (let ((buf (get-buffer "*spgit-branches*")))
    (when buf
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (spgit--branch-header))
          (insert (spgit--call-git '("branch")))
          (goto-char (point-min)))))))

(defun spgit-checkout (branch)
  "Switch to BRANCH."
  (interactive "sBranch name: ")
  (spgit--run `("checkout" ,branch) t))

(defun spgit-checkout-new (branch)
  "Create and switch to a new BRANCH."
  (interactive "sNew branch name: ")
  (spgit--run `("checkout" "-b" ,branch) t))

(defun spgit-branch-delete-prompt ()
  "Delete a branch interactively."
  (interactive)
  (let* ((branches (split-string (spgit--call-git '("branch")) "\n" t))
         (branch-list (mapcar (lambda (s) (if (string-prefix-p "* " s)
                                             (substring s 2)
                                           s))
                              branches))
         (current (spgit--current-branch-name))
         (branch (completing-read (format "Delete branch (current: %s): " current)
                                  branch-list nil t)))
    (unless (or (string-empty-p branch) (string-equal branch current))
      (if (y-or-n-p (format "Delete branch '%s'? " branch))
          (spgit--run `("branch" "-d" ,branch) t)
        (message "Aborted")))))

(provide 'spgit)

;;; spgit.el ends here
