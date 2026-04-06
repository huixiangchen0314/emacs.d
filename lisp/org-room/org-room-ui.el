;;; org-room-ui.el --- User interface for org-room  -*- lexical-binding: t; -*-

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

;; This module provides commands to show backlinks and other UI helpers.

;;; Code:

(require 'org-room-cache)

;;;###autoload
(defun org-room-show-backlinks ()
  "Show backlinks for the current note in a new buffer."
  (interactive)
  (unless (buffer-file-name)
    (user-error "Current buffer is not visiting a file"))
  (let* ((current-node (file-name-base (buffer-file-name)))
         (backlinks (org-room-cache-get-backlinks current-node)))
    (if (null backlinks)
        (message "No backlinks for %s" current-node)
      (with-output-to-temp-buffer "*org-room backlinks*"
        (with-current-buffer "*org-room backlinks*"
          (org-mode)
          (erase-buffer)
          (insert (format "Backlinks for [[%s]]:\n\n" current-node))
          (dolist (bl backlinks)
            (insert (format "- [[%s]]\n" bl)))
          (goto-char (point-min))
          (org-fold-reveal))))))

;;;###autoload
(defun org-room-insert-link ()
  "Insert a link to another note using completion."
  (interactive)
  (let ((node (completing-read "Link to note: " (org-room-cache-get-all-nodes))))
    (insert (format "[[%s]]" node))))

(provide 'org-room-ui)

;;; org-room-ui.el ends here
