;;ghc --make -no-hs-main ./triangle-opengl.c -o ghcmain.exe -lglfw3 -lopengl32 -lgdi32 -I./include -L./lib-mingw-w64 -I./deps

;; quickrun can execute current code file. if it hold basic program entry
;(e.g. Main Method in Java, main method in C/Cpp and if __main__ == "main" in python)
(use-package quickrun
  :ensure t
  :config
  (quickrun-add-command "haskell"
    '((:command . "stack")
      (:exec    . ("%c runghc %o %s %a"))
      (:timeout . 20))
    :override t)
  :bind
  ("C-z q r" . quickrun))

(provide 'init-quickrun)
