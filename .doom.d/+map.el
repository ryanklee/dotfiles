;;; ~/.doom.d/+map.el -*- lexical-binding: t; -*-

(after! org
  (map!
   (:leader
    :desc "Clock" :prefix "C"
     :desc "Clock-In"        :n "i" #'org-clock-in
     :desc "Clock-Out"       :n "o" #'org-clock-out
     :desc "Clock-In Last"   :n "C" #'org-clock-in-last
     :desc "Jump to current" :n "j" #'org-clock-jump-to-current-clock
     :desc "Pomodoro-Punch"    :n "p" #'org-pomodoro)))
