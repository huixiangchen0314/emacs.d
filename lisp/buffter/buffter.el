;;; buffter.el --- 轻量级外部命令格式化器（修正版）

(defun buffter--call-process (program args input)
  "调用外部程序 PROGRAM，参数为 ARGS，从字符串 INPUT 中读取数据。
返回两个值：格式化后的字符串（成功时）或 nil，以及错误信息（失败时）。"
  (let ((output-buffer (generate-new-buffer " *buffter output*"))
        (error-buffer  (generate-new-buffer " *buffter error*"))
        exit-code output error)
    (unwind-protect
        (progn
          (with-temp-buffer
            (insert input)
            (setq exit-code
                  (apply #'call-process-region
                         (point-min) (point-max)
                         program nil
                         (list output-buffer error-buffer)
                         nil
                         args)))
          (setq output (with-current-buffer output-buffer (buffer-string)))
          (setq error  (with-current-buffer error-buffer (buffer-string)))
          (if (and (zerop exit-code) (not (string-empty-p output)))
              (list output nil)
            (list nil (format "命令 %s 退出码 %d\nstderr: %s"
                              program exit-code error))))
      (kill-buffer output-buffer)
      (kill-buffer error-buffer))))

(defun buffter-format-region (program args begin end &optional replace-fn)
  "使用 PROGRAM 和 ARGS 格式化从 BEGIN 到 END 的区域。
如果 REPLACE-FN 为 nil，则默认用输出替换区域；
否则 REPLACE-FN 应为一个函数，接受输出字符串和原始内容，返回要插入的新内容。"
  (interactive
   (list (read-string "程序: ")
         (read-string "参数 (以空格分隔): ")
         (region-beginning) (region-end)))
  (let* ((original (buffer-substring-no-properties begin end))
         (result   (buffter--call-process program args original))
         (output   (car result))
         (err      (cadr result)))
    (if (not output)
        (message "格式化失败: %s" err)
      (let ((new-content (if replace-fn
                             (funcall replace-fn output original)
                           output)))
        (save-excursion
          (delete-region begin end)
          (goto-char begin)
          (insert new-content))
        (message "格式化成功")))))

(defun buffter-format-buffer (program args &optional replace-fn)
  "格式化当前整个缓冲区。"
  (interactive
   (list (read-string "程序: ")
         (read-string "参数 (以空格分隔): ")))
  (buffter-format-region program args (point-min) (point-max) replace-fn))

(cl-defmacro buffter-define (name &key program args)
  "定义一个格式化器，不生成模式行指示器。
NAME 是符号，将用于生成以下函数和模式：
- `NAME-format-buffer`   - 格式化整个缓冲区
- `NAME-format-region`   - 格式化选中区域
- `NAME-on-save-mode`    - 保存时自动格式化（全局模式）
- `NAME-enable-on-save`  - 在当前缓冲区启用保存时格式化（局部）
示例：
  (buffter-define my/lua-fmt
    :program \"npx\"
    :args '(\"lua-fmt\" \"--stdin\"))"
  (declare (indent 1))
  (let ((format-buffer-fn  (intern (format "%s-format-buffer" name)))
        (format-region-fn  (intern (format "%s-format-region" name)))
        (on-save-mode-fn   (intern (format "%s-on-save-mode" name)))
        (enable-on-save-fn (intern (format "%s-enable-on-save" name))))
    `(progn
       (defun ,format-region-fn (beg end)
         ,(format "格式化区域，使用命令 %s %s" program args)
         (interactive "r")
         (buffter-format-region ,program ',args beg end))
       
       (defun ,format-buffer-fn ()
         ,(format "格式化整个缓冲区，使用命令 %s %s" program args)
         (interactive)
         (,format-region-fn (point-min) (point-max)))
       
       (define-minor-mode ,on-save-mode-fn
         ,(format "Global minor mode to automatically format buffer before save using `%s'." name)
         :global t
         :lighter nil
         (if ,on-save-mode-fn
             (add-hook 'before-save-hook #',enable-on-save-fn)
           (remove-hook 'before-save-hook #',enable-on-save-fn)))
       
       (defun ,enable-on-save-fn ()
         ,(format "Enable `%s-format-buffer' before saving in Lua buffers." name)
         (when (derived-mode-p 'lua-mode 'lua-ts-mode)
           (condition-case err
               (,format-buffer-fn)
             (error (message "自动格式化失败: %s" err))))))))

(provide 'buffter)
