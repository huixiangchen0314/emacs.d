(use-package evil
  :ensure t
  :init
  (evil-mode)
  :config
  ;; 我不希望 Evil这个键 占据这么好的位置
  (unbind-key "C-z" 'evil-motion-state-map)
  (unbind-key "C-z" 'evil-insert-state-map)
  (unbind-key "^" 'evil-motion-state-map) ; 由Emacs的替代
  (unbind-key "$" 'evil-motion-state-map)
  ;; 小键盘优先， 这些键应该节省出来
 ; (unbind-key "h" 'evil-motion-state-map)
 ; (unbind-key "j" 'evil-motion-state-map)
 ; (unbind-key "k" 'evil-motion-state-map)
 ; (unbind-key "l" 'evil-motion-state-map)
  (unbind-key "C-d" 'evil-motion-state-map)
  (unbind-key "C-y" 'evil-motion-state-map)
  (unbind-key "C-e" 'evil-motion-state-map)

  (global-set-key (kbd "C-z v") 'hydra-evil/body)
 
  :bind
  ("S-<up>" . evil-scroll-line-up)
  ("S-<down>" . evil-scroll-line-down)
  ;;比较少用到的 Vim 指令就方这里
  :custom
  (evil-undo-system 'undo-tree)
  :hydra (hydra-evil (:hint nil)
		     ""
		     ("r" evil-redo "redp")
		     ("j" evil-join "join")
		     ("*" evil-search-word-forward "search forward")
		     ("#" evil-search-word-backward "search backword")
		     ("e" evil-scroll-line-down "line down")
		     ("u" evil-scroll-down "half page down")
		     ("f" evil-scroll-page-down "page down")
		     ("b" evil-scroll-page-up "page up")
		     ("q" nil  :color blue))
  :hook
  (evil-local-mode . global-undo-tree-mode)
  )


(provide 'init-evil)
