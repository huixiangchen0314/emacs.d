;;; _init.el --- Intializing file
;;; Commentary:

;;; Code:

(defconst lyt-home-directory "d:/")
(defconst lyt-emacs-directory "d:/emacs.d")
(defconst lyt-roam-directory "d:/roam")

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
(my/util/add-to-load-path (expand-file-name "lisp/lcltxt" my/emacs-dir))
(my/util/add-to-load-path (expand-file-name "lisp/stpl" my/emacs-dir))


(require 'init-editor)
(if (display-graphic-p)
    (progn
      (require 'init-gui)
      (require 'init-theme)))

(require 'init-prog)

(my/util/add-package-repo "elpa-origin" "https://melpa.org/packages/")
(my/util/add-package-repo "marmalade-origin"  "http://marmalade-repo.org/packages/")

(use-package emacs :ensure nil
  :init
  (setq-default tab-width 4)
  :custom
  (tab-always-indent t) ; alawy indent
  (indent-tabs-mode nil) ; ？
  :custom ; Custom --------------------------------------------------
  (backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory))))
  (url-history-file (expand-file-name "url/history" user-cache-directory))
  (auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" user-emacs-directory))
  (projectile-known-projects-file (expand-file-name "projectile-bookmarks.eld" user-emacs-directory))
  )
(require 'init-windows)
(require 'init-hydra)
(require 'init-evil)
(require 'init-helper)
(require 'init-undo-tree)
(require 'init-functions)
;;(require 'init-yasnippet)
(require 'init-eldoc)
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
(require 'init-java)
(require 'init-csharp)
(require 'init-lua)
(require 'init-org)
(require 'init-org-room)
(require 'init-treesit)
(require 'init-quickrun)
(require 'init-treemacs)

(require 'init-tabnine)
(require 'init-fetch-file)
(provide 'init)
;;; init.el ends here.


