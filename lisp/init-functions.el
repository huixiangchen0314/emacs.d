

(use-package highlight-symbol
  :ensure t
  :init (highlight-symbol-mode)
  :bind
  ("<f3>" . highlight-symbol))

(use-package avy
  :ensure t
  :chords
  ("jc" . avy-goto-char)
  ("jw" . avy-goto-word-1)
  ("jl" . avy-goto-line))



;; m1\n10 | int func%02d ()
;; M-x tiny-expand
(use-package tiny :ensure t)




(provide 'init-functions)
