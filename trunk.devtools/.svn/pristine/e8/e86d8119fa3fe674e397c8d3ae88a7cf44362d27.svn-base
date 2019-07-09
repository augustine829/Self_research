;;; Provides suitable compile commands for KreaTV.
;;;
;;; Example key bindings to add to .emacs or similar:
;;;
;;; (global-set-key [f5] 'compile)
;;; (global-set-key [f6] 'kreatv-compile-clean)
;;; (global-set-key [f7] 'kreatv-check-coding-style)

(require 'kreatv-env)

(set-default 'compile-command "make local_all NO_SCU=1")
(set-default 'kreatv-compile-clean-command "make local_clean")

(defun kreatv-compile-directory ()
  "Get the relative path to a directory where it is suitable start a compile."
  (cond
   ((file-exists-p "Makefile") nil)
   ((file-exists-p "../Makefile") "..")
   ((file-exists-p "../../Makefile") "../..")
   (t nil)))

(defun kreatv-set-default-compile-command ()
  (let ((path (kreatv-compile-directory))
	(command "make"))
    (when path (setq command (concat "cd " path " && " command)))
    (set (make-local-variable 'compile-command)
         (concat command " local_all NO_SCU=1"))
    (set (make-local-variable 'kreatv-compile-clean-command)
         (concat command " local_clean"))))

(defun kreatv-compile-clean ()
  "Run make local_clean for the current component"
  (interactive)
  (let ((compile-command kreatv-compile-clean-command))
    (call-interactively 'compile)))

(defun kreatv-check-coding-style ()
  "Run the script to check coding style"
  (interactive)
  ; Shadow compile-command to avoid compile setting global variable to
  ; .../check-coding-style, overriding user setting.
  (let (compile-command)
    (compile (concat kreatv-tools-directory "/bin/check-coding-style "
		     (kreatv-compile-directory)))))

(add-hook 'c-mode-common-hook 'kreatv-set-default-compile-command)

(provide 'kreatv-compile)
