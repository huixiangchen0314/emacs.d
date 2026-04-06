

(my/util/add-to-load-path (expand-file-name "lisp/buffter" my/emacs-dir))
(require 'buffter)

(buffter-define my/lua-fmt
  :program "npx"
  :args '("lua-fmt" "--stdin"))
;; lighter 是 Emacs 中用来定义 minor mode 在模式行（mode line）上显示的文字标签。它的主要作用是让你一眼就能知道当前缓冲区是否开启了这个 minor mode。
