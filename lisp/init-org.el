;;; _init.el ---  -*- lexical-binding: t; -*-
;;; Commentary:

;;; Code:


(require 'easyob)

(defvar
  my/org-auto-display-image-languages `("dot" "plantuml")
  "Languages that auto display generated image after code block executed.")

(use-package ob-lob :ensure nil
  :bind
  (:map org-mode-map
        ("C-c C-v" . hydra-ob/body)
        ("C-c '" . org-edit-special )
        ("C-c z i" . org-redisplay-inline-images ))
  :hydra (hydra-ob (:hint nil)
                   ("<up>" org-babel-previous-src-block "Jump to previous code block")
                   ("<down>" org-babel-next-src-block "Jump to next code block")
                   ("i" org-babel-lob-ingest "Import Babel Lib" )
                   ("t" org-babel-tangle "Tange Buffer" :color blue)
                   ("f" org-babel-tangle-file "Tangle to file" :color blue)
                   ("l" org-latex-preview "Toggle latex preview")
                   ("v" org-babel-expand-src-block "Preview noweb-expanded body in editing buffer" :color blue)
                   ("r" org-babel-open-src-block-result "View result in a additional buffer" :color blue))
  )


(defun _/org-display-execute-images ()
  "Display org inline images."
  (when-let ((lang (org-element-property :language (org-element-at-point))))
             (when (member lang my/org-auto-display-image-languages)
               (org-display-inline-images))))

(use-package org :ensure nil
  :init
  (unbind-key "S-<up>" 'org-mode-map)
  (unbind-key "S-<down>" 'org-mode-map)
  (unbind-key "C-k" 'org-mode-map) ; org-kill-line
  (unbind-key "C-j" 'org-mode-map) ; org-return-and-maybe-indent
  :config
  (add-hook 'org-babel-after-execute-hook '_/org-display-execute-images)
  :custom
  (org-support-shift-select nil) ;  shift ext-select
  (tab-width 8) ; org-mode 的 tab 宽度必须为8
  (org-image-actual-width `(300)) ; 图片显示的宽度
  )


(use-package ob :ensure nil
  :init
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((js                  . t)
	 (python              . t)
	 (C                   . t)
	 (java                . t)
	 (go                  . t)
	 (lua                 . t)
	 (emacs-lisp          . t)
	 (ruby                . t)
	 (shell               . t)
	 (css                 . t)
	 (awk                 . t)
	 (sql                 . t)
	 (plantuml            . t)
	 (dot                 . t)
     ))
  :custom
  (org-confirm-babel-evaluate nil)
  (org-babel-do-load-languages `())
  )
(use-package uuidgen :ensure t)
(use-package ob-rust :ensure t)
(use-package ob-go :ensure t)
(use-package ob-elixir :ensure t)
(use-package ob-prolog :ensure t)
(use-package graphviz-dot-mode :ensure t
  :config
  (define-derived-mode dot-mode graphviz-dot-mode "Dot"
    "Major mode for editing dot code."
    :group 'graphviz-dot))

(easyob-def latex
			"pdflatex -shell-escape -output-directory=$FILE_DIR $FILE && pdftoppm $FILE_SIMPLE.pdf -png $FILE_SIMPLE"
			:extension ".tex"
			:file "$FILE_SIMPLE-1.png"
			:head "
\\documentclass[varwidth,crop]{standalone}
\\usepackage{amsmath}
\\usepackage{mathtools}
\\usepackage{mathdots}
\\usepackage{esint}
\\usepackage{amssymb}
\\begin{document}
"
			:tail "
\\end{document}"
            )

(easyob-def haskell
            "runghc $FILE"
            :extension ".hs"
            :var "%S = %S")

(easyob-def ruby
            "ruby $FILE"
            :extension ".rb"
            :var "%S = %S")



;;(easyob-def lua
;;            "lua $FILE"
;;           :extension ".lua")

(use-package plantuml-mode :ensure t
  :custom
  (org-plantuml-jar-path  (expand-file-name  "vendor/jar/plantuml-bsd-1.2024.7.jar" my/emacs-dir)))


(provide 'init-org)

;;; init-org.el ends here.
