;;; _init.el --- Intializing file

;;; Commentary:
;; Initialize basic editor behaviour.
;;; Code:

;;; Keymap

(unbind-key "C-q"); 没人会花时间去手打非打印字符
(unbind-key "C-y")
(unbind-key "C-d")
(unbind-key "C-z") ; and not want to syspend Emacs
(unbind-key "<f3>") ; kmacro-start-macro-or-insert-counter
(unbind-key "<f4>") ; kmacro-end-or-call-macro
(unbind-key "C-j" ) ; electric-newline-and-mybe-index
(unbind-key "C-k") ; kill-line
(unbind-key "C-x o") ; other-window
(unbind-key "C-l") ; recenter-top-bottom

;;; Recenf. Healper to open recent files.
(require 'recentf)
(recentf-mode 1)
(setq recentf-max-saved-items 50)


;;; Adjust garbage collection threshold for early startup (see use of gcmh below)
(setq gc-cons-threshold 300000000 ; 300mb
      read-process-output-max (* 4 1024 1024)
      process-adaptive-read-buffering nil
      gc-cons-percentage 0.1)



(column-number-mode t) ; show line number
(global-visual-line-mode 1) ; Enable soft-wrap
(global-display-line-numbers-mode 1) ; show line number in window
(electric-pair-mode t) ; automatically fit paren
(show-paren-mode 1)
(add-hook 'prog-mode-hook #'hs-minor-mode) ; enable fold code trunk
(global-auto-revert-mode t ) ; immediately update buffer when other app modified file
(delete-selection-mode t) ; modify selection when keydown
(set-face-attribute 'default nil  :height 130)
(fido-vertical-mode)


;;(confirm-kill-processes nil) ; We don't care

(setq ring-bell-function 'ignore
      inhibit-startup-message t
      confirm-kill-emacs #'yes-or-no-p)


;; 设置语言环境
(set-language-environment "Chinese-GB")

(provide 'init-editor)
      
;;; init-editor.el ends here.
