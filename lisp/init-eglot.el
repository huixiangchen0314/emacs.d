;;; init-eglot.el --- Eglot setup -*- lexical-binding: t; -*-

;;; Commentary:

;; Eglot configuration: autoshutdown, eglot-ensure hook, and
;; language server entries for protobuf, lua, ruby, rust, and java.
;;
;; 原则：仅本文件使用的命令/函数一律 _/ 前缀

;;; Code:

(use-package eglot
  :ensure nil
  :custom
  (eglot-autoshutdown t)
  :hook (prog-mode . eglot-ensure)
  :config
  ;; Protobuf
  (add-to-list 'eglot-server-programs
               '((protobuf-mode) . ("buf" "language-server")))

  ;; Lua
  (add-to-list 'eglot-server-programs
               '((lua-mode lua-ts-mode) . ("lua-language-server")))

  ;; Ruby – Solargraph 默认不启诊断，通过初始化参数打开
  (add-to-list 'eglot-server-programs
               '((ruby-mode ruby-ts-mode) .
                 ("solargraph" "stdio"
                  :initializationOptions (:diagnostics t))))

  ;; Rust – clippy 检查 + 保存时 rustfmt
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode rust-mode) .
                 ("rust-analyzer"
                  :initializationOptions
                  (:check (:command "clippy")
                   :rustfmt (:enable t)))))

  ;; Java – jdtls（Eclipse JDT Language Server）
  (add-to-list 'eglot-server-programs
               '((java-mode java-ts-mode) . ("jdtls"))))

(provide 'init-eglot)
;;; init-eglot.el ends here
