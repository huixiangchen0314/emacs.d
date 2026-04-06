
(use-package tagedit :ensure t
  :config
  (require 'tagedit)
  (tagedit-add-paredit-like-keybindings)
  (unbind-key (kbd "M-?") 'tagedit-mode-map)
  (unbind-key (kbd "M-s") 'tagedit-mode-map)
)
