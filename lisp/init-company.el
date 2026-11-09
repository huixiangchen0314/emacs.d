;;; init-company.el --- Company setup -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(use-package company
  :ensure t
  :commands (global-company-mode)
  :init
  (global-company-mode)
  :custom
  (company-tooltip-align-annotations 't)
  (company-selection-wrap-around t)
  (company-transformers '(company-sort-by-occurrence))
  (company-minimum-prefix-length 1)
  (company-show-numbers t)
  (company-idle-delay 0) ;; 两秒后在进行代码提示
  )

(use-package company-box
  :ensure t
  :if (display-graphic-p)
  :hook (company-mode . company-box-mode))


(provide 'init-company)
;;; init-company.el ends here
