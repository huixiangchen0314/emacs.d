;;; init-yanippet.el --- Intializing file
;;; Commentary:

;;; Code:

(defun _/company-backend-with-yas (backend)
  (if (and (listp backend) (member 'company-yasnippet backend))
	  backend
    (append (if (consp backend) backend (list backend))
            '(:with company-yasnippet))))

(use-package yasnippet
  :custom
  (yas-snippet-dirs `(,(expand-file-name "yasnippets" my/emacs-dir)))
  :config
  (yas-global-mode 1)
    ;; unbind <TAB> completion
  (define-key yas-minor-mode-map [(tab)]        nil)
  (define-key yas-minor-mode-map (kbd "TAB")    nil)
  (define-key yas-minor-mode-map (kbd "<tab>")  nil)
  :bind
  (:map yas-minor-mode-map ("S-<tab>" . yas-expand))
  :bind
  ("C-z y" . hydra-yasnippet/body)
  :hydra (hydra-yasnippet (:hint nil)
                          ("n" yas-new-snippet "new snippet" :color blue)
                          ("v" yas-visit-snippet-file "edit snippet" :color blue)
                          ("r" yas-reload-all "reload snippet" :color blue)
                          ("s" yas-describe-tables "show snippets" :color blue) ; Show
                          ("q" nil "quit" :color blue))
  )


(use-package yasnippet-snippets  :ensure t)


(provide 'init-yasnippet)

;;; init-yasnippet.el ends here.
