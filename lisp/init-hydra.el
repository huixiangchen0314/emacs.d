
(use-package hydra :ensure t)

(use-package use-package-hydra
  :ensure t
  :config
  (defhydra hydra-zoom (global-map "<f2>")
    "zoom"
    ("g" text-scale-increase "in")
    ("l" text-scale-decrease "out")
    ("q" nil "quit" :color blue))
  )


;; Hydra Config for Emacs builtin
(use-package emacs :ensure nil
  ;; Key Macro
  :bind
  (("C-z k" . hydra-kmacro/body))
  :hydra (hydra-kmacro (:hint nil)
                       "Kbd Macro:   "
                       ("b" kmacro-start-macro-or-insert-counter "begin defining kbd macro")
                       ("e" kmacro-end-or-call-macro "end defining or call last kbd macro")
                       ("s" kmacro-name-last-macro "save last macro")
                       ("q" nil "quit" :color blue))
  ;; Bookmark
  :bind
  (("C-z m" . hydra-bookmark/body))
  :hydra (hydra-bookmark (:hint nil)
                         "bookmark  "
                         ("m" bookmark-set "mark" :color blue)
                         ("j" bookmark-jump "jump" :color blue)
                         ("l" bookmark-bmenu-list "list")
                         ("x" bookmark-delete "delete")
                         ("r" bookmark-rename "rename")
                         ("q" nil "quit" :color blue)))


(provide 'init-hydra)

;;; init-hydra.el ends here.
