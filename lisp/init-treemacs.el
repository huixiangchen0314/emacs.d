
(use-package treemacs
  :ensure t
  :defer t
  :config
  (treemacs-tag-follow-mode)
  :bind
  (:map treemacs-mode-map
	    ("/" . treemacs-advanced-helpful-hydra))
  :bind
  ("C-z t" . hydra-treemacs/body)
  :hydra (hydra-treemacs (:hint nil)
                         ("t" treemacs "open workspace" :color blue)
                         ("a" treemacs-add-project "add project" :color blue)
                         ("s" treemacs-select-directory "select dir" :color blue)
                         ("e" treemacs-edit-workspaces "edit workspace" :color blue)
                      ("q" nil "quit" :color blue))
    )

(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile))

(use-package treemacs-evil :ensure t )

(provide 'init-treemacs)

;;; init-treemacs,el ends here.
