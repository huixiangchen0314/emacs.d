;;; spgit.el --- Simple Git interface for Emacs  -*- lexical-binding: t; -*-

;; Provide simple commands for common Git operations without the complexity of Magit.
;; 调用 git 命令
;; 查看 git 输出
;;; Code:


(require 'spgit-core)
(require 'spgit-status)

(defun spgit--branch-header ()
  "Return a string with branch helper information."
  (concat
   "=== spgit branch helper ===\n"
   "Available keys: RET/SPC=switch to branch, d=delete branch, q=quit, ?=help\n"
   "============================\n\n"))

(defun spgit--history-header ()
  "Return a string with history helper information."
  (concat
   "=== spgit history helper ===\n"
   "Available keys: RET/SPC=show details, d=show diff, s=show stats, c=create branch,\n"
   "                i=interactive rebase (rewrite), v=revert (non-rewriting),\n"
   "                r=refresh, q=quit, ?=help\n"
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

;;; History (interactive log view)

(defun spgit-history ()
  "Show interactive commit history."
  (interactive)
  (let ((buf (get-buffer-create "*spgit-history*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert (spgit--history-header))
      (spgit-history-refresh)
      (goto-char (point-min))
      (spgit-history-mode))
    (display-buffer buf)))

(defvar spgit-history-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'spgit-history-show)
    (define-key map (kbd "SPC") 'spgit-history-show)
    (define-key map "d" 'spgit-history-diff)
    (define-key map "c" 'spgit-history-create-branch)
    (define-key map "s" 'spgit-history-stats)
    (define-key map "i" 'spgit-history-rebase)
    (define-key map "v" 'spgit-history-revert)
    (define-key map "r" 'spgit-history-refresh)
    (define-key map "q" 'quit-window)
    (define-key map "?" 'describe-mode)
    map)
  "Keymap for `spgit-history-mode'.")

(define-derived-mode spgit-history-mode special-mode "SpGit-History"
  "Major mode for interactive git history.
\\{spgit-history-mode-map}"
  (setq buffer-read-only t))

(defun spgit-history-refresh ()
  "Refresh the history buffer."
  (interactive)
  (let ((buf (get-buffer "*spgit-history*")))
    (when buf
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          ;; Clear everything after the header
          (delete-region (point-min) (point-max))
          (insert (spgit--history-header))
          (let ((default-directory (or (vc-root-dir) default-directory)))
            (insert (spgit--call-git `("log" "--oneline" "-n" ,(number-to-string spgit-history-limit)))))
          (goto-char (point-min)))))))

(defun spgit--hash-at-point ()
  "Return the commit hash at point, or nil if not found."
  (save-excursion
    (beginning-of-line)
    (if (looking-at "\\([a-f0-9]+\\) ")
        (match-string 1)
      nil)))

(defun spgit-history-show ()
  "Show detailed information about the commit at point."
  (interactive)
  (let ((hash (spgit--hash-at-point)))
    (if hash
        (spgit--run `("show" ,hash) t)
      (message "No commit at point"))))

(defun spgit-history-diff ()
  "Show diff of the commit at point."
  (interactive)
  (let ((hash (spgit--hash-at-point)))
    (if hash
        (spgit--run `("show" ,hash) t)
      (message "No commit at point"))))

(defun spgit-history-stats ()
  "Show statistics (git show --stat) of the commit at point."
  (interactive)
  (let ((hash (spgit--hash-at-point)))
    (if hash
        (spgit--run `("show" "--stat" ,hash) t)
      (message "No commit at point"))))

(defun spgit-history-create-branch ()
  "Create a new branch based on the commit at point."
  (interactive)
  (let ((hash (spgit--hash-at-point)))
    (if hash
        (let ((branch (read-string "New branch name: ")))
          (unless (string-empty-p branch)
            (spgit--run `("branch" ,branch ,hash) t)))
      (message "No commit at point"))))

(defun spgit--is-root-commit (hash)
  "Return t if HASH is a root commit (has no parent)."
  (let ((parent (ignore-errors
                  (string-trim (spgit--call-git `("rev-parse" ,(concat hash "^")))))))
    (or (not parent) (string-empty-p parent))))

(defun spgit-history-rebase ()
  "Start interactive rebase from the parent of the commit at point."
  (interactive)
  (let ((hash (spgit--hash-at-point)))
    (if hash
        (let* ((default-directory (or (vc-root-dir) default-directory))
               (cmd (format "git rebase -i %s"
                            (if (spgit--is-root-commit hash)
                                "--root"
                              (concat hash "^")))))
          (async-shell-command cmd "*spgit-rebase-output*")
          (message "Rebase started in background. Check buffer *spgit-rebase-output* and complete the rebase, then press r to refresh history."))
      (message "No commit at point"))))

(defun spgit-history-revert ()
  "Revert the commit at point (non-rewriting)."
  (interactive)
  (let ((hash (spgit--hash-at-point)))
    (if hash
        (when (y-or-n-p (format "Revert commit %s? " hash))
          (spgit--run `("revert" "--no-edit" ,hash) t))
      (message "No commit at point"))))

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
