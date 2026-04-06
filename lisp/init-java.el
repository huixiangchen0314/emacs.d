
(use-package java-ts-mode
  :mode "\\.java\\'"
  :mode "pom.xml\\'"
  :hook (java-ts-mode . subword-mode)
  ;; Tree-sitter 
  :bind (:map java-ts-mode-map
              ("C-z z" . 'hydra-ts-java/body))
  :hydra (hydra-ts-java (:hint nil)
                        ""
                          ("b" treesit-beginning-of-defun "To beginning of function")
                          ("e" treesit-end-of-defun "To end of function")
                          ("q" nil "Quit")
                          )
  ;; Eglot for ruby
  :bind (:map java-ts-mode-map
                ("C-z x" . 'hydra-eglot-java/body))
  :hydra (hydra-eglot-java (:hint nil)
                           ""
                             ("r" eglot-rename "Rename symbol")
                             ("f" eglot-format "Format buffer")
                             ("x" eglot-code-actions "Code actions")
                             ("i" eglot-inlay-hints-mode "Toggle inlay hint")
                             ("o" eglot-code-action-organize-imports "Organize imports")
                             ("h" eldoc-doc-buffer "Helper buffer")
                             ("d" xref-find-definitions "Find definitions")
                             ("q" nil "Quit"))
  
    ) ;; End of use-package java-ts-mode



(provide 'init-java)
