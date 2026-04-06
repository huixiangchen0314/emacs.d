;;; init-org-room.el --- Org-room configuration -*- lexical-binding:

;;; Commentary:

;;; Code:

(my/util/add-to-load-path (expand-file-name "lisp/org-room" my/emacs-dir))
(require 'org-room)
(org-room-initialize)
(add-hook 'org-mode-hook #'org-room-mode)

(provide 'init-org-room)

;;; init-org-room.el ends here
