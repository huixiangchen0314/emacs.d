;;; spgit-history.el --- History interface for spgit  -*- lexical-binding: t; -*-

(require 'spgit-core)
(require 'lcltxt)

;;; 国际化文本

(lcltxt-define spgit-history-header-hint
  :en "=== spgit history helper ===
Available keys: RET/SPC=show details, C-c d=show diff, C-c s=show stats,
                C-c c=create branch, C-c i=interactive rebase, C-c v=revert,
                r=refresh, q=quit, ?=help
============================

"
  :zh "=== spgit 历史助手 ===
可用按键：RET/SPC=显示详情，C-c d=显示差异，C-c s=显示统计，
       C-c c=创建分支，C-c i=交互式变基，C-c v=撤销提交，
       r=刷新，q=退出，?=帮助
============================

")

(lcltxt-define spgit-history-column-hash
  :en "Hash"
  :zh "哈希")

(lcltxt-define spgit-history-column-subject
  :en "Subject"
  :zh "主题")

;;; 核心渲染函数

(defun spgit--render-history-content ()
  "返回历史缓冲区的内容（头部 + 日志表格）。"
  (let ((log-output (spgit--call-git `("log" "--oneline" "-n" ,(number-to-string spgit-history-limit)))))
    (concat
     lcltxt-spgit-history-header-hint
     (format "%-8s %s\n" lcltxt-spgit-history-column-hash lcltxt-spgit-history-column-subject)
     (make-string 60 ?-) "\n"
     log-output)))

;;; 主命令

(defun spgit-history ()
  "Show interactive commit history."
  (interactive)
  (let ((buf (get-buffer-create "*spgit-history*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (spgit--render-history-content))
        (goto-char (point-min)))
      (spgit-history-mode))
    (display-buffer buf)))

;;; 刷新函数（保留光标位置）

(defun spgit-history-refresh ()
  "Refresh the history buffer, preserving cursor position by commit hash."
  (interactive)
  (let ((buf (get-buffer "*spgit-history*")))
    (when buf
      (with-current-buffer buf
        (let ((inhibit-read-only t)
              (current-hash nil)
              (new-pos nil))
          ;; 获取当前光标所在行的 commit hash
          (setq current-hash (spgit--hash-at-point))
          ;; 刷新内容
          (erase-buffer)
          (insert (spgit--render-history-content))
          ;; 尝试定位到相同 hash 的行
          (when current-hash
            (goto-char (point-min))
            (let ((case-fold-search nil))
              (if (re-search-forward (concat "^" (regexp-quote current-hash)) nil t)
                  (progn
                    (beginning-of-line)
                    (setq new-pos (point)))
                (goto-char (point-min)))))
          (when new-pos
            (goto-char new-pos)))))))

;;; 辅助函数

(defun spgit--hash-at-point ()
  "Return the commit hash at point, or nil if not found."
  (save-excursion
    (beginning-of-line)
    (if (looking-at "\\([a-f0-9]+\\) ")
        (match-string 1)
      nil)))

(defun spgit--is-root-commit (hash)
  "Return t if HASH is a root commit (has no parent)."
  (let ((parent (ignore-errors
                  (string-trim (spgit--call-git `("rev-parse" ,(concat hash "^")))))))
    (or (not parent) (string-empty-p parent))))

;;; 操作命令

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
        (spgit--run `("show" ,hash) t)   ; 与 show 相同，可单独定义
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

(defun spgit-history-rebase ()
  "Start interactive rebase from the parent of the commit at point."
  (interactive)
  (let ((hash (spgit--hash-at-point)))
    (if hash
        (let* ((default-directory (spgit--repository-root-path))
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

;;; 键映射（使用 C-c 前缀避免冲突）

(defvar spgit-history-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    ;; 保留 RET/SPC 为常用操作
    (define-key map (kbd "RET") #'spgit-history-show)
    (define-key map (kbd "SPC") #'spgit-history-show)
    ;; 其他操作使用 C-c 前缀
    (define-key map (kbd "C-c d") #'spgit-history-diff)
    (define-key map (kbd "C-c s") #'spgit-history-stats)
    (define-key map (kbd "C-c c") #'spgit-history-create-branch)
    (define-key map (kbd "C-c i") #'spgit-history-rebase)
    (define-key map (kbd "C-c v") #'spgit-history-revert)
    (define-key map "r" #'spgit-history-refresh)
    (define-key map "q" #'quit-window)
    (define-key map "?" #'describe-mode)
    map)
  "Keymap for `spgit-history-mode'.")

(define-derived-mode spgit-history-mode special-mode "SpGit-History"
  "Major mode for interactive git history.
\\{spgit-history-mode-map}"
  (setq buffer-read-only t))

(provide 'spgit-history)

;;; spgit-history.el ends here
