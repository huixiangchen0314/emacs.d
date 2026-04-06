

  ;; This package contains js-base-mode, js-mode, and js-ts-mode
  (use-package js-base-mode
    :defer 't
    :ensure js ;; I care about js-base-mode but it is locked behind the feature "js"
    :custom
    (js-indent-level 2)
    :config
    (add-to-list 'treesit-language-source-alist '(javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src"))
    (unbind-key "M-." js-base-mode-map))

  (use-package typescript-ts-mode
    :ensure typescript-ts-mode
    :defer 't
    :custom
    (typescript-indent-level 2)
    :config
    (add-to-list 'treesit-language-source-alist '(typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
    (add-to-list 'treesit-language-source-alist '(tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
    (unbind-key "M-." typescript-ts-base-mode-map))




(provide 'init-js)
