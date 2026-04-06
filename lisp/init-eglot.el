

(use-package eglot :ensure nil
  :custom
  (eglot-autoshutdown t)
  :hook (prog-mode . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '(protobuf-mode . ("buf" "language-server"))))

(provide 'init-eglot)
