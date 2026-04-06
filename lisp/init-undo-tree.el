

(use-package undo-tree
  :ensure t
  :config
  (global-undo-tree-mode)
  :bind ("C-z u" . hydra-undo-tree/body)
  :after hydra
  :hydra (hydra-undo-tree (:hint nil)
			  ""
			  ("p" undo-tree-undo "undo")
			  ("n" undo-tree-redo "redo")
			  ("s" undo-tree-save-history "save")
			  ("l" undo-tree-load-history "load")
			  ("u" undo-tree-visualize "visualize" :color blue)
			  ("q" nil "quit" :color blue))
  :custom
  (undo-tree-auto-save-history nil))

(provide 'init-undo-tree)
