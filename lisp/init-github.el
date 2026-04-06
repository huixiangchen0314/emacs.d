;;; init-github.el --- Github integration -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'init-git)

(use-package yagist :ensure nil)
(use-package bug-reference-github :ensure nil
  :hook
  ('prog-mode . 'bug-reference-prog-mode))

;;(use-package github-clone :ensure nil)
;;(use-package forge :ensure nil)
;;(use-package github-review :ensure nil)
(use-package flymake-actionlint :ensure nil
  :hook
  ('yaml-mode . 'flymake-actionlint-action-load-when-actions-file))

(provide 'init-github)
;;; init-github.el ends here.
