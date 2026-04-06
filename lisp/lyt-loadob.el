(require 'lyt-util)


(defconst lyt-loadob-dir
  (expand-file-name "babel-lib" lyt-note-directory))

(defvar lyt-loadob-file-list '())


(defun lyt-ob-expand-file-name-in-lib-dir(file-name)
  "Expand FILE-NAME in `org-babel-library-directory`."
  (expand-file-name file-name lyt-ob-lib-dir))


(defun lyt-ob-expand-file-name-list-in-lib-dir(file-name-list)
  "Expand FILE-NAME-LIST in `org-babel-library-directory`."
  (mapcar  (lambda (f)
	         (lyt-ob-expand-file-name-in-lib-dir f))
	       file-name-list))

(defun lyt-ob-add-lib(file-list)
  "Add FILE-LIST to the library of babel."
  (apply '+ (mapcar (lambda (f)
		      (setq lyt-ob-lib-file-list
			    (cons f lyt-ob-lib-file-list))
		      (org-babel-lob-ingest f))
		   file-list)))


(defun lyt-ob-reload-lib()
  "Docstring."
  (interactive )
  (lyt-ob-add-lib
   (lyt-util-list-files-in-dir
    lyt-ob-lib-dir
    "org"))
  (setq lyt-ob-lib-file-list
	(delete-dups lyt-ob-lib-file-list)))


(org-babel-lob-ingest "../../ytcg/org_example/ray_triangle_intersection.org")
