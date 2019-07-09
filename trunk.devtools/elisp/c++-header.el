;; Kreatel C++ Headers

(require 'kreatel-c++-header-common "c++-header-common.el")

(defun kreatel-insert-header ()
  (interactive)
  (kreatel-common-insert-header
   (file-name-nondirectory (buffer-file-name)) ""))

(defun kreatel-insert-header-stuff ()
  (interactive)
  (let ((filename
         (upcase (file-name-nondirectory (buffer-file-name)))))
    (while (string-match "\\.\\|/" filename)
      (setq filename (replace-match "_" t t filename)))
    (save-excursion
      (goto-char (point-min))
      (kreatel-insert-header)
      (insert (concat "#ifndef " filename "\n"))
      (insert (concat "#define " filename "\n\n"))
      (goto-char (point-max))
      (insert (concat "\n#endif\n")))))


(provide 'kreatel-c++-header)
