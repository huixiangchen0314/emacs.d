;;; _init.el --- Intializing file
;;; Commentary:
;;; Code:

;; Load platform specific configuration.
(cond
 ((eq system-type 'windows-nt)
  (defconst my/emacs-dir "d:/emacs.d")
  (add-to-list 'load-path
               (expand-file-name "lisp/platform/windows" my/emacs-dir)))
 ((eq system-type 'gnu/linux)
  (defconst my/emacs-dir "~/emacs.d")
  (add-to-list 'load-path
               (expand-file-name "lisp/platform/linux" my/emacs-dir)))
 (t
  (error "Unsupported system type")))

(add-to-list 'load-path
             (expand-file-name "lisp" my/emacs-dir))

(require 'init-setting)
(require 'init-utils)
(my/util/add-to-load-path-recursively (expand-file-name "vendor/lisp" my/emacs-dir))


(require 'init-editor)
(if (display-graphic-p)
    (progn
      (require 'init-gui)
      (require 'init-theme)))


(my/util/add-package-repo "elpa-origin" "https://melpa.org/packages/")
(my/util/add-package-repo "marmalade-origin"  "http://marmalade-repo.org/packages/")

(require 'init-windows)
(require 'init-hydra)
(require 'init-evil)
(require 'init-helper)
(require 'init-undo-tree)
(require 'init-functions)
(require 'init-yasnippet)
(require 'init-flymake)
(require 'init-company)
(require 'init-eglot)
(require 'init-platform)
(require 'init-lcltxt)
(require 'init-git)
(require 'init-github)
(require 'init-elisp)
(require 'init-ruby)
(require 'init-rails)
(require 'init-rust)
(require 'init-java)
(require 'init-lua)
(require 'init-org)
(require 'init-treesit)
(require 'init-quickrun)
(require 'init-treemacs)

(provide 'init)
;;; init.el ends here.


