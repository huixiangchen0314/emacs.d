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

(provide 'init-setting)
;;; init-setting.el ends here.
