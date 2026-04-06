(require 'lcltxt)

(lcltxt-define greeting
  :en "Hello"
  :zh "你好"
  :ja "こんにちは")

(message lcltxt-greeting)   ; 根据当前语言输出

(lcltxt-set-language 'zh)
(message lcltxt-greeting)   ; 输出 "你好"

(lcltxt-set-language 'en)
(message lcltxt-greeting)   ; 输出 "Hello"
