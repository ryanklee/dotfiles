;;; ~/.doom.d/+org.el -*- lexical-binding: t; -*-

(after! org
  (setq org-directory "~/Org/")
  (setq org-default-notes-file (concat org-directory "capture.org"))
  (setq org-agenda-files (list
                          (concat org-directory "home.org")
                          (concat org-directory "work.org")))
  (setq org-refile-targets (quote ((org-agenda-files :level . 1))))
  (setq org-capture-templates
        `(("t" "Todo to Inbox" entry
           (file+headline ,(concat org-directory "capture.org") "Inbox")
           "* TODO %? \n %i\n")

          ("T" "Todo and Clock In" entry
           (file+headline ,(concat org-directory "capture.org") "Inbox")
           "* TODO %? \n %i\n" :clock-in t :clock-keep t)

          ("e" "Create Event" entry
           (file+datetree+prompt ,(concat org-directory "events.org")
           "* %?\n%T" :empty-lines 0))

          ("E" "Create Event and Clock In" entry
           (file+datetree+prompt ,(concat org-directory "events.org")
           "* %?\n%T" :clock-in t :clock-keep t))

          ("n" "Note" entry (file ,(concat org-directory "capture.org")
           "* NOTE %?\n%U" :empty-lines 1))

          ("N" "Note with Clipboard" entry (file ,(concat org-directory "capture.org")
           "* NOTE %?\n%U\n   %c" :empty-lines 1))))

  (setq org-clock-in-resume t)
  (setq org-clock-out-when-done t)
  (setq org-clock-persist t)
  (setq org-clock-persist-query-resume nil)
  (setq org-clock-auto-clock-resolution (quote when-no-clock-is-running))
  (setq org-clock-report-include-clocking-task t)

 `(add-hook 'auto-save-hook 'org-save-all-org-buffers)`
  (add-hook 'org-mode-hook #'auto-fill-mode)
  (org-clock-persistence-insinuate)

  (setq org-bullets-bullet-list '("#"))
  )

(def-package! org-journal
  :config
  (setq org-journal-dir "/home/rlk/Org/Journal/")
  (setq org-journal-file-format "%Y-%m-%d")
  (setq org-journal-date-prefix "#+TITLE: ")
  (setq org-journal-date-format "%A, %B %d %Y")
  (setq org-journal-time-prefix "* ")
  (setq org-journal-time-format "[%R]"))


(after! org-super-agenda
 (setq org-super-agenda-groups
        '(
          (:name "Done"
                 :and (:regexp "State \"DONE\""
                               :log t))
          (:name "Clocked"
                 :log t)
          (:auto-category t)))
  )

(after! org-agenda
  (org-super-agenda-mode)
  (setq org-agenda-custom-commands
        '(("d" "Timeline for today" ((agenda ""))
           ((org-agenda-span 'day)
            (org-agenda-start-day "+0d")
            (org-agenda-show-log t)
            (org-agenda-log-mode-items '(clock closed))
            (org-agenda-clockreport-mode t)
            (org-agenda-entry-types '())))

          ("y" "Timeline for yesterday" ((agenda ""))
           ((org-agenda-span 'day)
            (org-agenda-start-day "-1d")
            (org-agenda-show-log t)
            (org-agenda-log-mode-items '(clock closed))
            (org-agenda-clockreport-mode t)
            (org-agenda-entry-types '())))

          ("w" "Timeline for week" ((agenda ""))
           ((org-agenda-span 'week)
            (org-agenda-start-day "-6d")
            (org-agenda-show-log t)
            (org-agenda-log-mode-items '(clock closed))
            (org-agenda-clockreport-mode t)
            (org-agenda-entry-types '())))))

  (defhydra +org@org-agenda-filter (:color pink :hint nil)
    "
_;_ tag      _h_ headline      _c_ category     _r_ regexp     _d_ remove    "
    (";" org-agenda-filter-by-tag)
    ("h" org-agenda-filter-by-top-headline)
    ("c" org-agenda-filter-by-category)
    ("r" org-agenda-filter-by-regexp)
    ("d" org-agenda-filter-remove-all)
    ("q" nil "cancel" :color blue))

  (set-popup-rule! "^\\*Org Agenda.*" :slot -1 :size 80 :side 'right :select t)
  (after! evil-snipe
    (push 'org-agenda-mode evil-snipe-disabled-modes))
(set-evil-initial-state! 'org-agenda-mode 'normal))

(setq alert-user-configuration
      (quote ((((:category . "org-pomodoro")) libnotify nil))))
