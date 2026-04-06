;;; init-ruby.el --- Ruby development setup  -*- lexical-binding: t; -*-

(use-package ruby-ts-mode
  :ensure t
  :mode (("\\.rb\\'" . ruby-mode)
         ("\\.rake\\'" . ruby-mode)
         ("\\.gemspec\\'" . ruby-mode)
         ("Rakefile\\'" . ruby-mode))
  :interpreter ("ruby" . ruby-mode)
  :config
  (setq ruby-indent-level 2)  ; 缩进 2 空格
  (add-hook 'ruby-mode-hook #'electric-pair-local-mode) ; 自动配对括号等
  )

(use-package inf-ruby
  :ensure t
  :hook (ruby-mode . inf-ruby-minor-mode)  ; 在 ruby-mode 中启用 inf-ruby 次要模式
  :config
  (setq inf-ruby-default-implementation "pry") ; 使用 pry 作为默认 REPL
  )

(use-package robe
  :ensure t
  :hook (ruby-mode . robe-mode)   ; 在 ruby-mode 中启用 robe
  :config
  (setq robe-use-pry t)           ; 使用 pry 进行代码导航
  )

(use-package rspec-mode
  :ensure t
  :hook (ruby-mode . rspec-mode)  ; 在 ruby-mode 中启用 rspec 相关键绑定
  :config
  (setq rspec-use-rake-when-possible t) ; 优先使用 rake 运行测试
  )

;; 语法检查
(use-package flycheck
  :ensure t
  :hook (ruby-mode . flycheck-mode))

;; 补全框架（如果还没配置全局 company）
(use-package company
  :ensure t
  :hook (ruby-mode . company-mode)
  :config
  (setq company-idle-delay 0.2))

;; 自动补全源：让 company 使用 robe 的后端
(with-eval-after-load 'company
  (add-to-list 'company-backends 'company-robe))

(provide 'init-ruby)
;;; init-ruby.el ends here
