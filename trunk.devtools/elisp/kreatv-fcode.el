;;; This file provides a fcode function which can be used to integrate
;;; the command devtools/bin/fcode into emacs.

(require 'kreatv-env)

(defun fcode (string directory)
  (interactive
   (list
    (read-string "Search string: " (thing-at-point 'symbol))
    (read-directory-name "Directory: ")))

  (grep-compute-defaults)
  (let ((grep-use-null-device nil))
    (grep (concat kreatv-tools-directory "/bin/fcode -n -p " directory
                  " '" (replace-regexp-in-string "'" "'\"'\"'" string) "'"))))

(provide 'kreatv-fcode)
