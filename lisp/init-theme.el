

;; Two theme. dark one *doom-themes* and light-dark toggle one *haven-andhell*
(use-package doom-themes :ensure t)

(use-package heaven-and-hell :ensure t
  :init
  (setq heaven-and-hell-theme-type 'dark)
  (setq heaven-and-hell-themes
   '((light . doom-feather-light)
     (dark . doom-tokyo-night)))
  :hook (after-init . heaven-and-hell-init-hook)
  :bind (("C-c <f6>" . heaven-and-hell-load-default-theme)
         ("<f6>" . heaven-and-hell-toggle-theme)))



(provide 'init-theme)
