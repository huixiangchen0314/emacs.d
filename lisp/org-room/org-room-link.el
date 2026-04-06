;;; org-room-link.el --- Follow links for org-room  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Your Name

;; Author: Your Name <you@example.com>
;; Keywords: org, notes

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

;; This module provides the `org-room-follow-link' function that handles
;; [[node]] links in Org mode. It also supports links with description
;; [[node][desc]] and links to headings [[node::heading]].

;;; Code:

(require 'org-room-cache)

(defun org-room-follow-link (&optional _)
  "Follow an org-room link at point.
Returns non‑nil if a link was followed, nil otherwise."
  (when (and (eq major-mode 'org-mode)
             (org-in-regexp org-link-bracket-re 1))
    (let* ((link-text (match-string-no-properties 1))
           (parts (split-string link-text "::"))
           (node (car parts))
           (heading (cadr parts)))
      (when (and node
                 (not (string-match-p "^\\." node)) ; not a relative file link
                 (not (file-name-absolute-p node)))
        (let ((target-file (org-room-cache-get-file node)))
          (if target-file
              (progn
                (find-file target-file)
                (when heading
                  (goto-char (point-min))
                  (re-search-forward (format "^\\*+ +%s" (regexp-quote heading))
                                     nil t))
                t)
            ;; Create new note
            (call-interactively #'org-room-find)
            t))))))

(provide 'org-room-link)

;;; org-room-link.el ends here
