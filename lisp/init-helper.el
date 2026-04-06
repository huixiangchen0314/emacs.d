

;; Key-Chord allows us to bind regular keyboard keys for various commands without having to use prefix keys such as Ctrl, Alt or Super etc.
(use-package use-package-chords
  :ensure t
  :init
  :custom((key-chord-two-keys-delay  0.4)
	      (key-chord-one-key-delay 0.5)) ;default 0.2
  :config
  (key-chord-mode 1))


(use-package amx :ensure t :init (amx-mode))

(use-package which-key :ensure t :init (which-key-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (use-package marginalia                       ;;
;;   :ensure t                                   ;;
;;   :init (marginalia-mode)                     ;;
;;   :bind (:map minibuffer-local-map            ;;
;; 	          ("M-A" . marginalia-cycle)))       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package nano-modeline
  :ensure t
  :init
  (nano-modeline-prog-mode t)
  :custom
  (nano-modeline-position 'nano-modeline-footer)
  :hook
  (prog-mode           . nano-modeline-prog-mode)
  (text-mode           . nano-modeline-text-mode)
  (org-mode            . nano-modeline-org-mode)
  (pdf-view-mode       . nano-modeline-pdf-mode)
  (mu4e-headers-mode   . nano-modeline-mu4e-headers-mode)
  (mu4e-view-mode      . nano-modeline-mu4e-message-mode)
  (elfeed-show-mode    . nano-modeline-elfeed-entry-mode)
  (elfeed-search-mode  . nano-modeline-elfeed-search-mode)
  (term-mode           . nano-modeline-term-mode)
  (xwidget-webkit-mode . nano-modeline-xwidget-mode)
  (messages-buffer-mode . nano-modeline-message-mode)
  (org-capture-mode    . nano-modeline-org-capture-mode))



(provide 'init-helper)
