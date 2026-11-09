;;; init-rust.el --- Support for the Rust language -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package rust-ts-mode
  :ensure nil
  :mode ("\\.rs\\'" . rust-ts-mode)
  :hook (rust-ts-mode . eglot-ensure))

(defun _/rust-cargo (subcommand)
  "Run `cargo SUBCOMMAND' in the nearest Cargo project root."
  (interactive
   (list (completing-read "Cargo: "
                          '("build" "test" "run" "check" "clippy" "doc" "bench")
                          nil nil nil nil "build")))
  (let* ((root (or (locate-dominating-file default-directory "Cargo.toml")
                   default-directory))
         (default-directory root))
    (compile (concat "cargo " subcommand))))

(with-eval-after-load 'rust-ts-mode
  (define-key rust-ts-mode-map (kbd "C-c c") #'_/rust-cargo))

(provide 'init-rust)
;;; init-rust.el ends here
