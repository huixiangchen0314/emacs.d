
(require 'frame)


(tool-bar-mode -1) ; close tool-bar
(toggle-scroll-bar -1) ; close scroll-bar



(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(setq default-file-name-coding-system "utf-8")
(prefer-coding-system 'utf-8)


(set-fontset-font t 'han (font-spec :family "Microsoft YaHei" :size 17))


;; Common icons for emacs
(use-package all-the-icons :ensure t)

(provide 'init-gui)
