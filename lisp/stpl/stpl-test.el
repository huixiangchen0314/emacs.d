(require 'stpl)

;; 1. Lisp 表达式求值（使用 {{ }}）
(stpl-render-with-env "Hello, {{ name }}" '((name . "Alice")))
;; => "Hello, Alice"

;; 2. 函数调用（无需外层括号）
(stpl-render-with-env "{{ concat \"Hello, \" name }}" '((name . "Bob")))
;; => "Hello, Bob"

;; 3. let 表达式（包含内部括号）
(stpl-render-with-env "{{ let ((x 10)) (+ x 5) }}" nil)
;; => "15"

;; 4. 空表达式
(stpl-render-with-env "{{ }}" nil)
;; => ""

;; 5. 子模板嵌套（使用 {% %}）
(stpl-render-with-env "{{ concat \"Hello, \" {% {{name}} %} }}" '((name . "World")))
;; => "Hello, World"

;; 6. 子模板内包含 Lisp 表达式
(stpl-render-with-env "{% {{ concat \"Hello, \" name }} %}" '((name . "Charlie")))
;; => "Hello, Charlie"

;; 7. 全局动态变量
(setq my-var "dynamic")
(stpl-render "Value: {{ my-var }}")
;; => "Value: dynamic"
