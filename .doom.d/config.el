;;; ~/.doom.d/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here

(load! "+org.el")
(load! "+ui.el")
`(add-hook 'auto-save-hook 'org-save-all-org-buffers)`
