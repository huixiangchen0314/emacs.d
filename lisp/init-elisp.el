

(use-package erefactor
  :ensure t
  :bind (:map emacs-lisp-mode-map
              ("C-c r" . erefactor-rename-symbol-in-buffer)))

(provide 'init-elisp)
