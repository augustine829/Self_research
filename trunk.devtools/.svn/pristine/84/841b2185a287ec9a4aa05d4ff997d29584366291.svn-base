(when (or (require 'gtags nil 'noerror)
          (require 'gtags "/usr/share/gtags/gtags" 'noerror))
  (defun gtags-update-sentinel (process event)
    (if (= (process-exit-status process) 0)
        (message "Updating GTAGS database...done")
      (message "Updating GTAGS database...FAILED")))

  (defun gtags-update ()
    (interactive)
    (message "Updating GTAGS database...")
    (set-process-sentinel
     (start-process "gtags-update" nil "gtags-update")
     'gtags-update-sentinel)))

(provide 'kreatv-gtags)
