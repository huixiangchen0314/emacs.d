;;; org-room-cache.el --- Cache for org-room notes  -*- lexical-binding: t; -*-

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

;; This module manages the in‑memory cache of note files and their links.
;; Node names are extracted from the `#+title:' keyword; if missing, the
;; file base name (without .org) is used as fallback.
;;
;; Tags are extracted from `#+filetags:' line or from a `:TAGS:' property
;; inside the `:PROPERTIES:' drawer.
;;
;; Links: both simple links `[[note]]`, links with description `[[note][desc]]`,
;; and links to headings `[[note::heading]]` are supported. For backlink
;; aggregation, the target node name is stripped of any `::heading` part,
;; so links to different headings of the same note are grouped together.

;;; Code:

(require 'org-element)

;; Forward declaration: org-room-directory is defined in org-room.el
(defvar org-room-directory)

(defvar org-room-cache--nodes nil
  "Alist (NODE-NAME . FILE-PATH).")
(defvar org-room-cache--links nil
  "Alist (NODE-NAME . (LIST-OF-LINKED-NODES)).")
(defvar org-room-cache--backlinks nil
  "Alist (NODE-NAME . (LIST-OF-NODES-THAT-LINK-TO-IT)).")
(defvar org-room-cache--tags nil
  "Alist (NODE-NAME . (LIST-OF-TAGS)).")
(defvar org-room-cache--tag-index nil
  "Alist (TAG . (LIST-OF-NODES-WITH-TAG)).")

(defun org-room-cache--extract-node-name (file)
  "Return node name for FILE, based on its #+title (or file name)."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (if (re-search-forward "^#\\+title:\\s-+\\(.*\\)" nil t)
        (match-string-no-properties 1)
      (file-name-base file))))

(defun org-room-cache--extract-tags (file)
  "Return list of tags for FILE.
Looks for #+filetags: line or :TAGS: property in :PROPERTIES: drawer."
  (with-temp-buffer
    (insert-file-contents file)
    (let ((tags nil))
      ;; 1. Check for #+filetags:
      (goto-char (point-min))
      (when (re-search-forward "^#\\+filetags:\\s-+\\(.*\\)" nil t)
        (let ((raw (match-string-no-properties 1)))
          (setq tags (split-string raw ":" t))))
      ;; 2. Check for :TAGS: property inside :PROPERTIES:
      (goto-char (point-min))
      (when (re-search-forward "^:PROPERTIES:" nil t)
        (let ((prop-start (point)))
          (when (re-search-forward "^:END:" nil t)
            (save-restriction
              (narrow-to-region prop-start (match-beginning 0))
              (goto-char (point-min))
              (when (re-search-forward "^:TAGS:\\s-+\\(.*\\)" nil t)
                (let ((raw (match-string-no-properties 1)))
                  (setq tags (append tags (split-string raw ":" t)))))))))
      (delete-dups tags))))

;;;###autoload
(defun org-room-cache-scan-directory ()
  "Scan `org-room-directory' and rebuild all caches."
  (interactive)
  (let* ((files (directory-files-recursively org-room-directory "\\.org$"))
         (nodes (mapcar (lambda (f) (cons (org-room-cache--extract-node-name f) f)) files))
         (links (mapcar (lambda (f)
                          (cons (org-room-cache--extract-node-name f)
                                (org-room-cache--extract-links f)))
                        files))
         (tags (mapcar (lambda (f)
                         (cons (org-room-cache--extract-node-name f)
                               (org-room-cache--extract-tags f)))
                       files)))
    (setq org-room-cache--nodes nodes
          org-room-cache--links links
          org-room-cache--tags tags)
    (org-room-cache--rebuild-backlinks)
    (org-room-cache--rebuild-tag-index)))

(defun org-room-cache--extract-links (file)
  "Return list of node names linked from FILE.
Supports both `[[node]]` and `[[node][description]]` formats,
as well as `[[node::heading]]`. The `::heading` part is stripped
so that links to different headings of the same node are grouped
together in backlinks."
  (with-temp-buffer
    (insert-file-contents file)
    (let ((links))
      (org-element-map (org-element-parse-buffer) 'link
        (lambda (link)
          (when (string= (org-element-property :type link) "fuzzy")
            (let ((raw (org-element-property :path link)))
              (when raw
                ;; Remove any `::heading` part, keep only the node name
                (let ((node (car (split-string raw "::"))))
                  (push node links)))))))
      (delete-dups links))))

(defun org-room-cache--rebuild-backlinks ()
  "Rebuild backlinks index from current links."
  (let ((backlinks (make-hash-table :test 'equal)))
    (dolist (entry org-room-cache--links)
      (let ((source (car entry))
            (targets (cdr entry)))
        (dolist (target targets)
          (puthash target
                   (cons source (gethash target backlinks))
                   backlinks))))
    (setq org-room-cache--backlinks
          (mapcar (lambda (k) (cons k (reverse (gethash k backlinks))))
                  (hash-table-keys backlinks)))))

(defun org-room-cache--rebuild-tag-index ()
  "Rebuild tag index from current tags."
  (let ((tag-index (make-hash-table :test 'equal)))
    (dolist (entry org-room-cache--tags)
      (let ((node (car entry))
            (tags (cdr entry)))
        (dolist (tag tags)
          (puthash tag
                   (cons node (gethash tag tag-index))
                   tag-index))))
    (setq org-room-cache--tag-index
          (mapcar (lambda (k) (cons k (reverse (gethash k tag-index))))
                  (hash-table-keys tag-index)))))

(defun org-room-cache-update-file (file)
  "Update cache for a single FILE."
  (let* ((node (org-room-cache--extract-node-name file))
         (new-links (org-room-cache--extract-links file))
         (new-tags (org-room-cache--extract-tags file)))
    ;; Update nodes
    (setq org-room-cache--nodes
          (assoc-delete-all node org-room-cache--nodes))
    (push (cons node file) org-room-cache--nodes)
    ;; Update links
    (setq org-room-cache--links
          (assoc-delete-all node org-room-cache--links))
    (push (cons node new-links) org-room-cache--links)
    ;; Update tags
    (setq org-room-cache--tags
          (assoc-delete-all node org-room-cache--tags))
    (push (cons node new-tags) org-room-cache--tags)
    ;; Rebuild indexes
    (org-room-cache--rebuild-backlinks)
    (org-room-cache--rebuild-tag-index)))

(defun org-room-cache-get-all-nodes ()
  "Return list of all note names."
  (mapcar #'car org-room-cache--nodes))

(defun org-room-cache-get-file (node)
  "Return file path for NODE, or nil if not found."
  (cdr (assoc node org-room-cache--nodes)))

(defun org-room-cache-get-backlinks (node)
  "Return list of nodes that link to NODE."
  (cdr (assoc node org-room-cache--backlinks)))

(defun org-room-cache-get-tags (node)
  "Return list of tags for NODE."
  (cdr (assoc node org-room-cache--tags)))

(defun org-room-cache-get-tag-index ()
  "Return the full tag index (TAG . NODES)."
  org-room-cache--tag-index)

(defun org-room-cache-get-nodes-by-tag (tag)
  "Return list of nodes that have TAG."
  (cdr (assoc tag org-room-cache--tag-index)))

(defun org-room-cache-cleanup ()
  "Remove cache entries for files that no longer exist.
This function iterates through all cached nodes, checks if the
file exists, and removes those that are missing. It also rebuilds
the links, tags, and backlinks accordingly."
  (let ((new-nodes nil)
        (new-links nil)
        (new-tags nil))
    ;; Filter nodes that still exist
    (dolist (entry org-room-cache--nodes)
      (let ((file (cdr entry)))
        (if (file-exists-p file)
            (push entry new-nodes)
          (message "org-room: Removing missing file %s from cache" file))))
    (setq org-room-cache--nodes (nreverse new-nodes))
    ;; Filter links to only keep nodes that still exist
    (dolist (entry org-room-cache--links)
      (let ((node (car entry)))
        (when (assoc node org-room-cache--nodes)
          (push entry new-links))))
    (setq org-room-cache--links (nreverse new-links))
    ;; Filter tags to only keep nodes that still exist
    (dolist (entry org-room-cache--tags)
      (let ((node (car entry)))
        (when (assoc node org-room-cache--nodes)
          (push entry new-tags))))
    (setq org-room-cache--tags (nreverse new-tags))
    ;; Rebuild indexes
    (org-room-cache--rebuild-backlinks)
    (org-room-cache--rebuild-tag-index)))

(provide 'org-room-cache)

;;; org-room-cache.el ends here
