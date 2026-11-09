;;; init-flymake.el --- Flymake setup -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode))

(provide 'init-flymake)
;;; init-flymake.el ends here
