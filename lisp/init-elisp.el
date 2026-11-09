;;; init-elisp.el --- Elisp editing setup -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;; C-z / 绑定到 comment-line，包在 with-eval-after-load 里避免加载顺序问题
(with-eval-after-load 'prog-mode
  (define-key prog-mode-map (kbd "C-z /") 'comment-line))


(use-package rainbow-delimiters
  :hook (emacs-lisp-mode . rainbow-delimiters-mode))

;;; C-h . get local helper info
(use-package eldoc :ensure nil
  :init
  (global-eldoc-mode))



(use-package erefactor
  :ensure t
  :bind (:map emacs-lisp-mode-map
              ("C-c r" . erefactor-rename-symbol-in-buffer)))

(provide 'init-elisp)
;;; init-elisp.el ends here
