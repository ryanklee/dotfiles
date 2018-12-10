;;; ~/.doom.d/+ui.el -*- lexical-binding: t; -*-

(setq doom-font (font-spec :family "Input Mono Narrow"
                           :size 13
                           :weight 'semi-light)
       +modeline-height 25)

(setq doom-big-font (font-spec :family "Input Mono Narrow"
                           :size 15
                           :weight 'semi-light)
       +modeline-height 25)

(require 'doom-themes)
(setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
      doom-themes-enable-italic t) ; if nil, italics is universally disabled
(load-theme 'doom-nord t)
(doom-themes-visual-bell-config)
(doom-themes-treemacs-config)
(doom-themes-org-config)

(def-package! moody
  :config
  (setq x-underline-at-descent-line t)
  (setq moody-mode-line-height 20)
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode))

(def-package! minions
  :config
  (minions-mode 1))
