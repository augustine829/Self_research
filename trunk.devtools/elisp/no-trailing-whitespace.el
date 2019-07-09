;;; no-trailing-whitespace -- keep your source free from trailing whitespace
;;
;; Copyright (C) 2009-2010 Joel Rosdahl
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. Neither the name of the author nor the names of its contributors
;;    may be used to endorse or promote products derived from this software
;;    without specific prior written permission.
;;
;; ============================================================================
;;
;; This file installs some hooks so that you won't inadvertently add any
;; trailing whitespace to your code. If no trailing whitespace exists in a file
;; when it is opened, all trailing whitespace is removed when the buffer is
;; saved, so that files without trailing whitespace stay that way. Thus, the
;; behaviour is conservative: if there is any preexisting trailing whitespace
;; in the file, it is kept (along with any newly introduced trailing
;; whitespace).
;;
;; Two commands and one variable are also provided:
;;
;; - The buffer-local `auto-remove-trailing-whitespace' variable says whether
;;   trailing whitespace will be removed when saving the buffer. The variable
;;   is set to t when a file without trailing whitespace is loaded.
;;
;; - The `toggle-auto-remove-trailing-whitespace' command toggles
;;   `auto-remove-trailing-whitespace'. Use this command if you want to add
;;   trailing whitespace to a file without preexisting trailing whitespace.
;;
;; - The `delete-trailing-whitespace-and-keep-doing-so' command deletes
;;   trailing whitespace in the current buffer and sets
;;   `auto-remove-trailing-whitespace' to t.
;;
;;; INSTALLATION
;;; ============
;;
;; Put
;;
;;   (require 'no-trailing-whitespace)
;;
;; or (if needed)
;;
;;   (require 'no-trailing-whitespace "/path/to/no-trailing-whitespace.el")
;;
;; in your .emacs file.
;;
;; You may also want to add some key bindings, for example:
;;
;;   (global-set-key (kbd "<f11>") 'delete-trailing-whitespace-and-keep-doing-so)
;;   (global-set-key (kbd "<C-f11>") 'toggle-auto-remove-trailing-whitespace)

(defvar auto-remove-trailing-whitespace nil
  "*Whether the maybe-remove-trailing-whitespace function should
remove trailing whitespace.")
(make-variable-buffer-local 'auto-remove-trailing-whitespace)

(defun toggle-auto-remove-trailing-whitespace ()
  "Toggle whether trailing whitespace should be deleted when saving the buffer."
  (interactive)
  (make-local-variable 'auto-remove-trailing-whitespace)
  (setq auto-remove-trailing-whitespace (not auto-remove-trailing-whitespace))
  (message
   "%semoving trailing whitespace when saving."
   (if auto-remove-trailing-whitespace "R" "Not r")))

(defun buffer-contains-trailing-whitespace ()
  (save-excursion
    (goto-char (point-min))
    (search-forward-regexp "[ \r\t]$" nil 'noerror)))

(defun set-auto-remove-trailing-whitespace ()
  (if (not (buffer-contains-trailing-whitespace))
      (setq auto-remove-trailing-whitespace t)
    (message (concat "Warning: File contains trailing whitespace;"
                     " will not automatically remove"))))

(defun maybe-remove-trailing-whitespace ()
  "Remove trailing whitespace from all lines in the current
buffer if and only if auto-remove-trailing-whitespace is non-nil."
  (when auto-remove-trailing-whitespace
    (delete-trailing-whitespace))
  nil) ; Return nil --> don't stop calling other write file hooks.

(defun delete-trailing-whitespace-and-keep-doing-so ()
  "Delete trailing whitespace in the current buffer and make sure that it also
is deleted when saving the buffer."
  (interactive)
  (delete-trailing-whitespace)
  (setq auto-remove-trailing-whitespace t))

(add-hook 'find-file-hook 'set-auto-remove-trailing-whitespace)
(add-hook 'write-file-functions 'maybe-remove-trailing-whitespace)

(provide 'no-trailing-whitespace)
