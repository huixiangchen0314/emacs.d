;;; init-setting.el --- Intializing file
;;; Commentary:
;; Generic togglable setting for configuration.
;;; Code:

(defconst *spell-check-support-enabled* nil)

;; Adjust garbage collection threshold for early startup (see use of gcmh below)
(setq gc-cons-threshold (* 128 1024 1024)) 

;; Process performance tuning

(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)


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


(provide 'init-setting)
;;; init-setting.el ends here.
