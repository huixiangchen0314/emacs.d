;;; _init.el --- Intializing file

;;; Commentary:
;; Shotcut for windows switch.
;;; Code:

;;; Keymap



(add-hook 'after-init-hook 'winner-mode)

;;; Windmove
(require 'windmove)
(global-set-key (kbd "C-<left>") 'windmove-left)
(global-set-key (kbd "C-<right>") 'windmove-right)
(global-set-key (kbd "C-<up>") 'windmove-up)
(global-set-key (kbd "C-<down>") 'windmove-down)
;;(unbind-key (kbd "C-<up>") 'eshell-hist-mode-map)
;;(unbind-key (kbd "C-<dowm>") 'eshell-hist-mode-map)
(setq windmove-wrap-around t)
(winner-mode 1)

;; visually select window to forward.
(use-package switch-window :ensure t
  :init
  (setq-default switch-window-shortcut-style 'qwerty)
  (setq-default switch-window-timeout nil)
  (global-set-key (kbd "C-x 5") 'switch-window)
  )


;; When splitting window, show (other-buffer) in the new window

(defun my/i/split-window-func-with-other-buffer (split-function)
  (lambda (&optional arg)
    "Split this window and switch to the new window unless ARG is provided."
    (interactive "P")
    (funcall split-function)
    (let ((target-window (next-window)))
      (set-window-buffer target-window (other-buffer))
      (unless arg
        (select-window target-window)))))

;; Rearrange split windows

(defun my/i/split-window-horizontally-instead ()
  "Kill any other windows and re-split such that the current window is on the top half of the frame."
  (interactive)
  (let ((other-buffer (and (next-window) (window-buffer (next-window)))))
    (delete-other-windows)
    (split-window-horizontally)
    (when other-buffer
      (set-window-buffer (next-window) other-buffer))))

(defun my/i/split-window-vertically-instead ()
  "Kill any other windows and re-split such that the current window is on the left half of the frame."
  (interactive)
  (let ((other-buffer (and (next-window) (window-buffer (next-window)))))
    (delete-other-windows)
    (split-window-vertically)
    (when other-buffer
      (set-window-buffer (next-window) other-buffer))))

(provide 'init-windows)

;;; init-windows.el ends here.
