;;; init-rails.el --- Rails project support  -*- lexical-binding: t; -*-

(use-package projectile-rails
  :ensure t
  :hook (ruby-mode . projectile-rails-mode)  ; 在 ruby-mode 中启用
  :config
  (setq projectile-rails-keymap-prefix (kbd "C-c r"))) ; 设置快捷键前缀

;; 可选：增强的 Rails 模式（与 projectile-rails 互补）
;; (use-package rails-mode
;;   :ensure t
;;   :hook (ruby-mode . rails-mode)  ; 如果使用 rails-mode，注意与 projectile-rails 可能有重叠
;;   ;; 通常建议只选其一，这里以 projectile-rails 为主，注释掉 rails-mode
;;   )

;; 配置 rake 命令（可选）
(use-package rake
  :ensure t
  :defer t)

;; 方便运行 Rails 服务器、控制台等
(defun my/i/rails-console ()
  "Open Rails console in a new window."
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (compile "rails console")))

(defun my/i/rails-server ()
  "Start Rails server in a new window."
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (compile "rails server")))

;; 添加快捷键到 projectile-rails 菜单（可选）
(with-eval-after-load 'projectile-rails
  (define-key projectile-rails-mode-map (kbd "C-c r c") #'my-rails-console)
  (define-key projectile-rails-mode-map (kbd "C-c r s") #'my-rails-server))

(provide 'init-rails)
;;; init-rails.el ends here
