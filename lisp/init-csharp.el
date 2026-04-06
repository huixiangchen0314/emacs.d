

(use-package csharp-ts-mode
  :mode "\\.cs\\'"
  :hook (csharp-ts-mode . subword-mode)
  ;; Tree-sitter 
  :bind (:map csharp-ts-mode-map
              ("C-z z" . 'hydra-ts-csharp/body))
  :hydra (hydra-ts-csharp (:hint nil)
                        ""
                          ("b" treesit-beginning-of-defun "To beginning of function")
                          ("e" treesit-end-of-defun "To end of function")
                          ("q" nil "Quit")
                          )
  :bind (:map csharp-ts-mode-map
                ("C-z x" . 'hydra-eglot-csharp/body))
  :hydra (hydra-eglot-csharp (:hint nil)
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



(provide 'init-csharp)
