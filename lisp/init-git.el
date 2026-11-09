;;; init-git.el --- git configuration -*- lexical-binding:

;;; Commentary:

;;; Code:

;; 提供针对 Git 相关配置文件的 major mode，例如 .gitignore、.gitattributes、.git/config 等文件，实现语法高亮、自动补全（部分）和基础编辑辅助。
(use-package git-modes :ensure nil)

;; 让你在 Emacs 中像“时间机器”一样浏览当前文件的 Git 历史版本。
;; 在任意受 Git 管理的文件中运行 M-x git-timemachine，会打开一个新 buffer，显示该文件的旧版本
;; 可以通过快捷键 p（上一个版本）、n（下一个版本）、g（跳转到指定 commit）等来导航，直观查看文件演变过程。
(use-package git-timemachine :ensure nil)

;; 快速生成当前文件在远程 Git 仓库（GitHub、GitLab、Bitbucket 等）中的链接。
;; 运行 M-x git-link，会复制当前文件在仓库中的 Web 浏览链接（如
;; https://github.com/user/repo/blob/master/path/to/file#L42）到剪贴板或回显区域，方便分享代码片段或跳转到浏览器查看。
(use-package git-link :ensure nil)

(provide 'init-git)

;;; init-git.el ends here
