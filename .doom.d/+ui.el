;;; ~/.doom.d/+ui.el -*- lexical-binding: t; -*-

(setq doom-font (font-spec :family "Input Mono Narrow"
                           :size 13
                           :weight 'semi-light)
       +modeline-height 25)

(setq doom-big-font (font-spec :family "Input Mono Narrow"
                           :size 15
                           :weight 'semi-light)
       +modeline-height 25)

(def-package! moody
  :config
  (setq x-underline-at-descent-line t)
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode))

(def-package! minions
  :config
  (minions-mode 1))
