;;; stpl.el --- Simple template engine with {{ ... }} and {% ... %}  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Your Name

;; Author: Your Name <your@email.com>
;; Keywords: convenience, lisp
;; Version: 2.2
;; Package-Requires: ((emacs "24.3") (cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A simple template engine for Emacs Lisp supporting:
;;
;;   {{ ... }}  — evaluate Emacs Lisp expression (after replacing inner {% ... %})
;;   {% ... %}  — recursively render sub‑template
;;
;; They can be arbitrarily nested.
;;
;; Examples:
;;   (stpl-render "hello, {{ user-login-name }}")
;;   => "hello, your-username"
;;
;;   (stpl-render-with-env "{{ concat \"Hello, \" name }}" '((name . "Alice")))
;;   => "Hello, Alice"
;;
;;   (stpl-render-with-env "{{ let ((x 10)) (+ x 5) }}" nil) => "15"
;;   (stpl-render-with-env "{{ }}" nil) => ""

;;; Code:

(require 'cl-lib)

(defun stpl--find-matching-delimiter (str start open close)
  "Find matching CLOSE delimiter for OPEN in STR starting at START.
OPEN and CLOSE are strings (e.g., \"{{\" and \"}}\").
Returns the position after the matching CLOSE delimiter, or nil if not found."
  (let ((open-len (length open))
        (close-len (length close))
        (count 1)
        (i start))
    (while (and (< i (length str)) (> count 0))
      (cond
       ((and (<= (+ i open-len) (length str))
             (string= (substring str i (+ i open-len)) open))
        (setq count (1+ count)
              i (+ i open-len)))
       ((and (<= (+ i close-len) (length str))
             (string= (substring str i (+ i close-len)) close))
        (setq count (1- count))
        (if (= count 0)
            (setq i (+ i close-len))
          (setq i (+ i close-len))))
       (t
        (setq i (1+ i)))))
    (if (= count 0) i nil)))

(defun stpl--replace-percent-braces-in-expr (expr-str env)
  "Replace each {% ... %} in EXPR-STR with its rendered result as a quoted string.
Rendering uses ENV (an alist) for variable bindings.
Returns the modified string suitable for `read'."
  (let ((result "")
        (i 0)
        (len (length expr-str)))
    (while (< i len)
      (if (and (< i (- len 1))
               (string= (substring expr-str i (+ i 2)) "{%"))
          (let ((start (+ i 2)))
            (let ((end (stpl--find-matching-delimiter expr-str start "{%" "%}")))
              (if (not end)
                  (error "Unmatched {% in expression: %s" expr-str)
                (let* ((inner (substring expr-str start (- end 2))) ; remove trailing "%}"
                       (rendered (stpl-render-with-env inner env))
                       (quoted (prin1-to-string rendered)))
                  (setq result (concat result quoted)
                        i end)))))
        (setq result (concat result (substring expr-str i (1+ i)))
              i (1+ i))))
    result))

(defun stpl--parse-expression (str)
  "Parse STR as a Lisp expression, adding parentheses if needed.
If the result is a single-element list (e.g., (name)), return its element.
Otherwise return the form as is."
  (if (string-match-p "\\`\\s-*\\'" str)
      nil
    (let* ((wrapped (concat "(" str ")"))
           (form (car (read-from-string wrapped))))
      (if (and (listp form) (= (length form) 1) (not (listp (car form))))
          (car form)
        form))))

;;;###autoload
(defun stpl-render-with-env (str env)
  "Render template string STR with variable environment ENV.
ENV is an alist of (SYMBOL . VALUE) pairs.  Inside {{ ... }} expressions,
these bindings are available (overriding global dynamic bindings).

Supports:
  {{ ... }}  — evaluate Emacs Lisp expression (after replacing inner {% ... %})
  {% ... %}  — recursively render sub‑template (using same ENV)

Arbitrary nesting is allowed."
  (let ((result "")
        (i 0)
        (len (length str)))
    (while (< i len)
      (cond
       ;; Handle {{ ... }}  (Lisp expression)
       ((and (< i (- len 1))
             (string= (substring str i (+ i 2)) "{{"))
        (let ((start (+ i 2)))
          (let ((end (stpl--find-matching-delimiter str start "{{" "}}")))
            (if (not end)
                (error "Unmatched {{ in template: %s" str)
              (let* ((inner (substring str start (- end 2))) ; remove trailing "}}"
                     (inner-processed (stpl--replace-percent-braces-in-expr inner env))
                     (expr-result
                      (if (string-match-p "\\`\\s-*\\'" inner-processed)
                          ""
                        (let ((form (stpl--parse-expression inner-processed)))
                          (eval `(cl-progv ',(mapcar #'car env)
                                          ',(mapcar #'cdr env)
                                        ,form)
                                t)))))
                (setq result (concat result (if (stringp expr-result)
                                                expr-result
                                              (format "%s" expr-result)))
                      i end))))))
       ;; Handle {% ... %}  (sub-template rendering)
       ((and (< i (- len 1))
             (string= (substring str i (+ i 2)) "{%"))
        (let ((start (+ i 2)))
          (let ((end (stpl--find-matching-delimiter str start "{%" "%}")))
            (if (not end)
                (error "Unmatched {% in template: %s" str)
              (let* ((inner (substring str start (- end 2)))
                     (rendered (stpl-render-with-env inner env)))
                (setq result (concat result rendered)
                      i end))))))
       ;; Plain text
       (t
        (setq result (concat result (substring str i (1+ i)))
              i (1+ i)))))
    result))

;;;###autoload
(defun stpl-render (str)
  "Render template string STR using the current dynamic environment.
This is a compatibility wrapper around `stpl-render-with-env' that does not
introduce any extra variable bindings (i.e., only global/dynamic variables
are visible)."
  (stpl-render-with-env str nil))

(provide 'stpl)

;;; stpl.el ends here
