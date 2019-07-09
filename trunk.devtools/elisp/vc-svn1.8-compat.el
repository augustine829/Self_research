;;; Load this file to make vc-mode work with SVN 1.8 in older Emacsen.

(require 'vc-svn)

(unless (functionp 'vc-svn-root)
  ;; vc-find-root, vc-svn-root and vc-svn-registered originate from Emacs 24.4.

  (defun vc-find-root (file witness)
    "Find the root of a checked out project.
The function walks up the directory tree from FILE looking for WITNESS.
If WITNESS if not found, return nil, otherwise return the root."
    (let ((locate-dominating-stop-dir-regexp
           (or vc-ignore-dir-regexp locate-dominating-stop-dir-regexp)))
      (locate-dominating-file file witness)))

  (defun vc-svn-root (file)
    (vc-find-root file vc-svn-admin-directory))

  (defun vc-svn-registered (file)
    "Check if FILE is SVN registered."
    (when (vc-svn-root file)
      (with-temp-buffer
        (cd (file-name-directory file))
        (let* (process-file-side-effects
               (status
                (condition-case nil
                    ;; Ignore all errors.
                    (vc-svn-command t t file "status" "-v")
                  ;; Some problem happened.  E.g. We can't find an `svn'
                  ;; executable.  We used to only catch `file-error' but when
                  ;; the process is run on a remote host via Tramp, the error
                  ;; is only reported via the exit status which is turned into
                  ;; an `error' by vc-do-command.
                  (error nil))))
          (when (eq 0 status)
            (let ((parsed (vc-svn-parse-status file)))
              (and parsed (not (memq parsed '(ignored unregistered)))))))))))

(provide 'vc-svn1.8-compat)
