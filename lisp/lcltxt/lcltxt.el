;;; lcltxt.el --- 本地化文本支持（自动生成变量 lcltxt-<key>）  -*- lexical-binding: t; -*-

;; 本库提供国际化功能，通过 `lcltxt-define' 定义翻译，
;; 自动生成变量 `lcltxt-KEY'，其值为当前语言的翻译。

;;; Code:

(defgroup lcltxt nil
  "本地化文本支持库."
  :group 'l10n)

(defcustom lcltxt-current-language nil
  "当前使用的语言符号，如 'en, 'zh, 'ja。如果为 nil，则从 `current-language-environment' 自动推断。"
  :type '(choice (const :tag "自动检测" nil)
                 (symbol :tag "语言符号"))
  :group 'lcltxt)

(defvar lcltxt--translations (make-hash-table :test 'eq)
  "哈希表，键为符号 KEY，值为 alist '((lang . string) ...)。")

(defvar lcltxt--defined-variables nil
  "已通过 `lcltxt-define' 定义的变量列表（符号）。")

(defvar lcltxt-language-change-hook nil
  "当语言改变时运行此钩子。")

;;; 辅助函数

(defun lcltxt--detect-language ()
  "根据环境返回合适的语言符号.
中文: Chinese-*, 返回 zh
日语: Japanese, 返回 ja
法语: French, 返回 fr
德语: German, 返回 de
其他: 返回 en。"
  (or lcltxt-current-language
      (let ((lang-env current-language-environment))
        (cond
         ((or (string-match-p "Chinese" lang-env)
              (string-match-p "\\`zh" lang-env))
          'zh)
         ((string-match-p "Japanese" lang-env)
          'ja)
         ((string-match-p "French" lang-env)
          'fr)
         ((string-match-p "German" lang-env)
          'de)
         (t 'en)))))

(defun lcltxt--get-translation (key &optional lang)
  "返回 KEY 对应的翻译。
KEY 为符号。若指定 LANG 则使用该语言，否则自动检测。
回退顺序：指定语言 -> 英语 -> 第一个有定义的 -> 占位符。"
  (let* ((target-lang (or lang (lcltxt--detect-language)))
         (translations (gethash key lcltxt--translations))
         (translation (cdr (assoc target-lang translations))))
    (or translation
        (cdr (assoc 'en translations))
        (cdar translations)  ; 第一个有定义的
        (format "<unknown-local-text:%s>" key))))

(defun lcltxt--update-all-variables ()
  "刷新所有通过 `lcltxt-define' 生成的变量值。"
  (dolist (var lcltxt--defined-variables)
    (let* ((var-name (symbol-name var))
           ;; 变量名格式为 "lcltxt-<key>"，去掉前缀 "lcltxt-"
           (key (intern (substring var-name (length "lcltxt-"))))
           (new-value (lcltxt--get-translation key)))
      (set var new-value))))

;;; 核心宏

;;; 核心宏（修正版）

(defmacro lcltxt-define (key &rest plist)
  "定义符号 KEY 的翻译。
PLIST 为 `:lang \"string\"' 形式的属性列表。
同时生成变量 `lcltxt-KEY'，其值为当前语言的翻译。
示例:
  (lcltxt-define greeting
    :en \"Hello\"
    :zh \"你好\"
    :ja \"こんにちは\")"
  (declare (indent 1))
  (let* ((var-name (intern (format "lcltxt-%s" key)))
         (langs ())
         (strings ()))
    (while plist
      (let ((lang (pop plist))
            (str  (pop plist)))
        ;; 将关键字 :en 转换为普通符号 'en
        (push (if (keywordp lang)
                  (intern (substring (symbol-name lang) 1))
                lang)
              langs)
        (push str strings)))
    `(progn
       (puthash ',key ',(cl-loop for lang in (reverse langs)
                                 for str in (reverse strings)
                                 collect (cons lang str))
                lcltxt--translations)
       (defvar ,var-name nil
         ,(format "本地化文本：%s（根据当前语言自动更新）" key))
       (setq ,var-name (lcltxt--get-translation ',key))
       (add-to-list 'lcltxt--defined-variables ',var-name)
       ,var-name)));;; 语言切换

(defun lcltxt-set-language (lang)
  "设置当前语言为 LANG (符号)，并刷新所有变量，运行钩子。"
  (interactive "S语言符号: ")
  (setq lcltxt-current-language lang)
  (lcltxt--update-all-variables)
  (run-hooks 'lcltxt-language-change-hook))

;;; 交互命令

(defun lcltxt-refresh ()
  "刷新所有本地化变量的值，根据当前语言环境重新获取翻译."
  (interactive)
  (lcltxt--update-all-variables)
  (message "Localization variables refreshed. Current language: %s"
           (lcltxt--detect-language)))

(defun lcltxt-show-language ()
  "显示当前检测到的语言符号."
  (interactive)
  (let ((lang (lcltxt--detect-language)))
    (message "Current language symbol: %s (from %s)"
             lang
             (if lcltxt-current-language
                 (format "custom setting '%s'" lcltxt-current-language)
               "environment detection"))))

(defun lcltxt-reset-language ()
  "清除自定义语言设置，恢复到从环境自动检测，并刷新变量."
  (interactive)
  (setq lcltxt-current-language nil)
  (lcltxt--update-all-variables)
  (message "Language detection reset to environment. Current language: %s"
           (lcltxt--detect-language)))

;;; 备选函数（非必须）

(defun lcltxt-tr (key)
  "函数式获取 KEY 的翻译（不依赖自动变量）。"
  (lcltxt--get-translation key))

(provide 'lcltxt)

;;; lcltxt.el ends here
