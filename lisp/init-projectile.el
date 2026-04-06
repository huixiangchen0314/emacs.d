;;; init-projectile.el --- Use Projectile for navigation within projects -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package projectile :ensure t
  :config
  ;; Shorter modeline
  (setq-default projectile-mode-line-prefix " Proj")
  (when (executable-find "rg")
    (setq-default projectile-generic-command "rg --files --hidden -0"))
  :hook
  ('after-init-hook . `projectile-mode))

(use-package ibuffer-projectile :ensure nil)
;;; init-projectile.el ends here
