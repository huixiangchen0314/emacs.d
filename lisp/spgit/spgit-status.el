
(require 'spgit-core)

;;; Hint Text:

(lcltxt-define spgit-status-header-hint
  :en
  "=== spgit status helper ===
Symbols: first = staged, second = working tree
M = modified, A = added, D = deleted, R = renamed, C = copied
U = updated but unmerged, ? = untracked, (space) = unchanged

Available keys: C-c a=add, C-c A=add all, C-c c=commit, C-c r=refresh, C-c b=switch branch, C-c B=new branch,
                C-c h=history, q=quit, ?=help
============================

"
  :zh "=== spgit 状态助手 ===
符号：第一列 = 暂存区，第二列 = 工作区
M = 已修改，A = 已添加，D = 已删除，R = 已重命名，C = 已复制
U = 已更新但未合并，? = 未跟踪，(空格) = 未更改

可用按键：C-c a=添加，C-c A=全部添加，C-c c=提交，C-c r=刷新，C-c b=切换分支，C-c B=新建分支，
       C-c h=历史，q=退出，?=帮助
============================

")

(lcltxt-define spgit-status-column-staged
  :en "Staged"
  :zh "暂存区")

(lcltxt-define spgit-status-column-worktree
  :en "Worktree"
  :zh "工作区")

(lcltxt-define spgit-status-column-file
  :en "File"
  :zh "文件")

(lcltxt-define spgit-status-current-branch-label
  :en "Branch"
  :zh "当前分支")


;;; Buffer:

(defun spgit-status ()
  "Show git status in a buffer with basic actions."
  (interactive)
  (let ((buf (get-buffer-create "*spgit-status*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (spgit--render-status-content))
        (goto-char (point-min)))
      (spgit-status-mode))
    (display-buffer buf)))

(defun spgit--render-status-content ()
  "返回用于状态缓冲区的内容字符串（包含头部、分支、美化后的状态）。"
  (concat
   lcltxt-spgit-status-header-hint
   (format "%s: %s\n\n" lcltxt-spgit-status-current-branch-label (spgit--current-branch-name))
   (spgit--lint-status-message
    (spgit--expand-untracked-dirs
     (spgit--call-git '("status" "--short"))))))

(defun spgit--lint-status-message (status-string)
  "美化 STATUS-STRING（git status --short 的输出）。
添加列首提示（已本地化），并对齐暂存区和工作区的状态符号。"
  (let ((lines (split-string status-string "\n" t))
        (result '()))
    ;; 添加列首提示（使用 lcltxt 变量）
    (push (format "%-6s %-8s %s"
                  lcltxt-spgit-status-column-staged
                  lcltxt-spgit-status-column-worktree
                  lcltxt-spgit-status-column-file)
          result)
    (push (make-string 25 ?-) result)  ; 分隔线，长度可根据需要调整
    ;; 处理每一行
    (dolist (line lines)
      (if (string-match "^\\s-*\\(.\\)\\(.\\)\\s-+\\(.+\\)" line)
          (let ((staged (match-string 1 line))
                (work (match-string 2 line))
                (file (match-string 3 line)))
            (setq staged (if (string= staged " ") "-" staged))
            (setq work   (if (string= work " ")   "-" work))
            (push (format "%-6s %-8s %s" staged work file) result))
        (push line result)))
    (mapconcat #'identity (nreverse result) "\n")))


(defun spgit--expand-untracked-dirs (status-string)
  "将 STATUS-STRING 中的未跟踪目录（?? dir）展开，保留目录行并在其后列出所有未跟踪文件。"
  (let ((lines (split-string status-string "\n" t))
        (new-lines '()))
    (dolist (line lines)
      (if (string-match "^\\?\\? \\(.+\\)/?$" line)   ; 匹配 ?? dir 或 ?? dir/
          (let ((path (match-string 1 line)))
            (if (file-directory-p (expand-file-name path (spgit--repository-root-path)))
                (progn
                  ;; 1. 保留原目录行
                  (push line new-lines)
                  ;; 2. 获取目录下所有未跟踪文件（递归）
                  (let ((output (spgit--call-git `("ls-files" "--others" "--exclude-standard" "--" ,path))))
                    (dolist (file (split-string output "\n" t))
                      (push (format "?? %s" file) new-lines))))
              ;; 不是目录（例如普通文件），直接保留
              (push line new-lines)))
        (push line new-lines)))
    (mapconcat #'identity (nreverse new-lines) "\n")))
;;; Major Mode And Keyboard Map:

;;; C-c 开头避开了大部分常用冲突了.关键是不会与 eval 冲突.
(defvar spgit-status-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map (kbd "C-c a") #'spgit-status-add)
    (define-key map (kbd "C-c A") #'spgit-status-add-all)   ; 新增
    (define-key map (kbd "C-c c") #'spgit-status-commit)
    (define-key map (kbd "C-c r") #'spgit-status-refresh)
    (define-key map (kbd "C-c b") #'spgit-status-branch-switch)
    (define-key map (kbd "C-c B") #'spgit-status-branch-new)
    (define-key map (kbd "C-c h") #'spgit-history)
    (define-key map "q" #'quit-window)
    (define-key map "?" #'describe-mode)
    map)
  "Keymap for `spgit-status-mode'.")

(define-derived-mode spgit-status-mode special-mode "SpGit"
  "Major mode for spgit status buffer.
\\{spgit-status-mode-map}"
  (setq buffer-read-only t))



;;; Commands:

(defun spgit--extract-path-from-status-line (line)
  "从状态行 LINE 中提取文件名。
支持原始 `git status --short` 输出以及美化后的输出。"
  (cond
   ;; 美化后的格式：两列状态（可能为字母或 '-'），每列宽度固定，文件名在最后
   ((string-match "^\\S-+\\s-+\\S-+\\s-+\\(.+\\)" line)
    (match-string 1 line))
   ;; 原始格式：两个状态字符（可能有空格），后跟空格，再跟文件名
   ((string-match "^[ MADRCU?][ MADRCU?] \\(.+\\)" line)
    (match-string 1 line))
   (t nil)))

(defun spgit-status-add ()
  "Add file at point to staging area."
  (interactive)
  (let* ((line (buffer-substring (line-beginning-position) (line-end-position)))
        (file (spgit--extract-path-from-status-line line)))
    (if file
        (let* ((repo-root (spgit--repository-root-path))
               (absolute-file (expand-file-name file repo-root)))
          (spgit--run `("add" ,absolute-file) nil)
          (spgit-status-refresh))
      (message "Cannot determine file at point"))))

(defun spgit-status-add-all ()
  "Add all changes (including untracked files) to staging area."
  (interactive)
  (spgit--run '("add" "--all") nil)   ; 不显示输出 buffer
  (message "All changes added")
  (spgit-status-refresh))


(defun spgit-status-commit ()
  "Commit staged changes."
  (interactive)
  (spgit-commit))

(defun spgit-status-refresh ()
  "Refresh the status buffer, preserving cursor position by file name."
  (interactive)
  (let ((buf (get-buffer "*spgit-status*")))
    (when buf
      (with-current-buffer buf
        (let ((inhibit-read-only t)
              (current-file nil)
              (new-pos nil))
          ;; 1. 获取当前光标所在行的文件名（如果有）
          (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
            (setq current-file (spgit--extract-path-from-status-line line)))
          ;; 2. 刷新内容（使用统一渲染函数）
          (erase-buffer)
          (insert (spgit--render-status-content))
          ;; 3. 如果之前有文件名，尝试在新内容中定位
          (when current-file
            (goto-char (point-min))
            (let ((case-fold-search nil))
              (if (re-search-forward (regexp-quote current-file) nil t)
                  (progn
                    (beginning-of-line)
                    (setq new-pos (point)))
                (goto-char (point-min)))))
          (when new-pos
            (goto-char new-pos)))))))

(defun spgit-status-branch-switch ()
  "Switch to a different branch using a branch list buffer."
  (interactive)
  (let* ((branches (split-string (spgit--call-git '("branch")) "\n" t))
         (branch-list (mapcar (lambda (s) (if (string-prefix-p "* " s)
                                             (substring s 2)
                                           s))
                              branches))
         (current (spgit--current-branch-name))
         (branch (completing-read (format "Switch to branch (current: %s): " current)
                                  branch-list nil t)))
    (unless (string-empty-p branch)
      (spgit--run `("checkout" ,branch) t)
      (spgit-status-refresh))))

(defun spgit-status-branch-new ()
  "Create and switch to a new branch."
  (interactive)
  (let ((branch (read-string "New branch name: ")))
    (unless (string-empty-p branch)
      (spgit--run `("checkout" "-b" ,branch) t)
      (spgit-status-refresh))))

(provide 'spgit-status)

;;; spgit-status.el ends here.
