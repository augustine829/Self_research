;;; Load this file to keep the copyright years in source code files up to date
;;; automatically.

(defun kreatv-copyright-parse-years (string)
  "Parse a string containing years (example: 2003, 2005, 2008-2010) into a
range cons pair (example: (2003 . 2010)."
  (save-match-data
    (let ((years (mapcar 'string-to-number
                         (split-string
                          (replace-regexp-in-string "[ \t,-]+" "," string)
                          ","))))
      (cons (apply 'min years) (apply 'max years)))))

(defun kreatv-copyright-current-year ()
  "Return current year as an integer."
  (nth 5 (decode-time)))

(defun kreatv-copyright-format-copyright-row (years)
  (format
   "Copyright (c) %s ARRIS Enterprises, LLC. All rights reserved."
   years))

(defun kreatv-copyright-comment-start ()
  (cond ((eq major-mode 'c-mode) "// ")
        ((eq major-mode 'emacs-lisp-mode) ";;; ")
        (t comment-start)))

(defconst kreatv-copyright-arris-blurb
  "This program is confidential and proprietary to ARRIS Enterprises, LLC.
(ARRIS), and may not be copied, reproduced, modified, disclosed to others,
published or used, in whole or in part, without the express prior written
permission of ARRIS.")

;; This regexp matches a "/* */", "//", ";" or "#" style comment (excluding any
;; shebang line).
(defconst kreatv-copyright-top-header-re
  "^\\(#![^\n]*\n+\\)?\\(/\\*\\(\\(.\\|\n\\)*?\\)\\*/\n\\|\\(\\(//\\|[;#]\\)\\(\\(.\\|\n\\)*?\\)\n\\)+\\)")

;; This regexp matches an old-style C++ comment. Subexpression 1 contains the
;; text between the dashed rows.
(defconst kreatv-copyright-old-style-c++-top-header-re
  (concat
   ;; Comment start, potentially with a mode specification:
   "^/\\* *\\(?:-\\*- *[Mm]ode:.*-\\*- *\n\\)?"
   ;; Zero or more empty rows followed by a row of dashes:
   "[ *\n]+-\\{40,\\}"
   ;; Some text:
   "\\(\\(?:.\\|\n\\)*?\\)"
   ;; A row of dashes:
   "-\\{40,\\}"
   ;; Zero or more empty rows followed by comment end:
   "[ *\n]+\\*/"))

;; This regexp matches a single ARRIS copyright row. Subexpression 1 contains
;; the year range.
(defconst kreatv-copyright-arris-copyright-row-re
  "Copyright ([cC]) \\([0-9][0-9, -]*\\) ARRIS Enterprises, LLC.*")

;; This regexp matches any copyright row. Subexpression 1 contains the comment
;; prefix.
(defconst kreatv-copyright-any-copyright-row-re
  "^\\(.*\\)Copyright ([cC]).*")

(defun kreatv-copyright-fix-old-comment-text (text)
  (save-match-data
    ;; Remove leading and trailing cruft on lines:
    (setq text (replace-regexp-in-string "^ *\\* ?\\(.*?\\) *$" "\\1" text))
    ;; Remove filename, if any:
    (setq text (replace-regexp-in-string "^[ \n]*[A-Za-z0-9_/]*?\.\\(h\\|c\\|cpp\\)\n" "" text))
    ;; Remove old Motorola blurb, if any:
    (setq text (replace-regexp-in-string "This program is confidential and proprietary to Motorola\\(.\\|\n\\)*" "" text))
    ;; Switch place between copyright rows and file description, if any:
    (setq text (replace-regexp-in-string "\\`\\(\\(?:.\\|\n\\)*?\\)\\(Copyright (c)\\(?:.\\|\n\\)*\\)\\'" "\\2\\1" text))
    ;; Tidy up multiple blank lines:
    (setq text (replace-regexp-in-string "\n\\{3,\\}" "\n\n" text))
    ;; Remove leading and trailing whitespace:
    (setq text (replace-regexp-in-string "\\`[ \n]*\\(\\(?:.\\|\n\\)*?\\)[ \n]*\\'" "\\1" text))
    ;; Add comment prefix:
    (setq text (replace-regexp-in-string "^" "// " text))
    text))

(defun kreatv-copyright-fix-old-style-comment ()
  (let ((orig-point (point)))
    (goto-char (point-min))
    (when (looking-at kreatv-copyright-old-style-c++-top-header-re)
      (let ((text (kreatv-copyright-fix-old-comment-text (match-string 1))))
        (replace-match
         (if (string= major-mode "c-mode")
             (format "// -*- Mode: C -*-\n//\n%s" text)
           text))))))

(defun kreatv-copyright-add-copyright-if-needed ()
  (goto-char (point-min))
  (when (and (not (search-forward-regexp
                   kreatv-copyright-arris-copyright-row-re nil 'noerror))
             (search-backward-regexp kreatv-copyright-any-copyright-row-re
                                     nil 'noerror))
    (next-line)
    (beginning-of-line)
    (insert (match-string 1))
    (insert (kreatv-copyright-format-copyright-row
             (kreatv-copyright-current-year)))
    (insert "\n")))

(defun kreatv-copyright-update-copyright ()
  (goto-char (point-max))
  (when (search-backward-regexp kreatv-copyright-arris-copyright-row-re
                                nil 'noerror)
    (let ((current-year (kreatv-copyright-current-year))
          (year-range (kreatv-copyright-parse-years (match-string 1))))
      (unless (= (cdr year-range) current-year)
        (replace-match
         (format "%d-%d" (car year-range) current-year)
         nil
         nil
         nil
         1)))))

(defun kreatv-copyright-remove-any-old-blurb ()
  (goto-char (point-min))
  (when (search-forward-regexp
         "^.*This program is confidential and proprietary to \\(Motorola\\|ARRIS \\(Enterprises\\|Group\\), Inc\\)"
         nil 'noerror)
    (forward-line -1)
    (set-mark (point))
    (forward-line 5)
    (delete-region (mark) (point))))

(defun kreatv-copyright-add-blurb-if-needed ()
  (goto-char (point-min))
  (when (and (not (save-excursion
                    (search-forward-regexp
                     "\\(General\\|Mozilla\\)[ \t]+Public[ \t]+License" nil 'noerror)))
             (not (search-forward-regexp
                   "This program is confidential and proprietary to ARRIS Enterprises, LLC"
                   nil 'noerror))
             (search-backward-regexp "^\\(.*\\)Copyright.*ARRIS" nil 'noerror))
    (forward-line 1)
    (set-mark (point))
    (insert (format "\n%s\n" kreatv-copyright-arris-blurb))
    (forward-line -1)
    (string-rectangle (mark) (point) (match-string 1))))

(defun kreatv-copyright-symbol-bound-and-true (mode)
  (and (boundp mode) (symbol-value mode)))

(defun kreatv-copyright-should-update ()
  (not (or (kreatv-copyright-symbol-bound-and-true 'emerge-mode)
           (kreatv-copyright-symbol-bound-and-true 'smerge-mode))))

(defun kreatv-copyright-update-header ()
  (when (and (not undo-in-progress) (kreatv-copyright-should-update))
    (save-match-data
      (save-excursion
        (let ((orig-point (point)))
          (goto-char (point-min))
          (when (and (looking-at kreatv-copyright-top-header-re)
                     (> orig-point (match-end 0)))
            (save-restriction
              (narrow-to-region (match-beginning 0) (match-end 0))
              ;; Now we are only looking at the top comment.
              (kreatv-copyright-fix-old-style-comment)
              (kreatv-copyright-add-copyright-if-needed)
              (kreatv-copyright-update-copyright)
              (kreatv-copyright-remove-any-old-blurb)
              (kreatv-copyright-add-blurb-if-needed)
              (delete-trailing-whitespace))))))))

(defun kreatv-copyright-update-copyright-soon ()
  ;; Queue a call to `kreatv-copyright-update-header'. We can't call
  ;; `kreatv-copyright-update-header' immediately from `first-change-hook'
  ;; because some editor commands (for instance `open-line' and
  ;; `transpose-chars') save the point location before doing buffer
  ;; modifications and then restores point to the saved location before doing
  ;; more modifications. The saved location may then refer to the wrong
  ;; location if `first-change-hook' has modified the buffer.
  (run-at-time 0 nil 'kreatv-copyright-update-header))

(defun kreatv-copyright-activate-for-this-buffer ()
  (add-hook
   'first-change-hook 'kreatv-copyright-update-copyright-soon nil 'local))

(defun kreatv-add-copyright ()
  "Add a copyright header at the beginning of the buffer."
  (interactive)
  (goto-char (point-min))
  (insert (format "%s\n\n%s\n\n"
                  (kreatv-copyright-format-copyright-row
                   (kreatv-copyright-current-year))
                  kreatv-copyright-arris-blurb))
  (previous-line 2)
  (string-rectangle (point-min) (point) (kreatv-copyright-comment-start))
  (forward-line)
  (save-restriction
    (narrow-to-region (point-min) (point))
    (delete-trailing-whitespace)))

;; Update copyright in all cc-mode modes as well as Emacs Lisp, Perl, Python
;; and sh modes.
(add-hook 'c-mode-common-hook 'kreatv-copyright-activate-for-this-buffer)
(add-hook 'emacs-lisp-mode-hook 'kreatv-copyright-activate-for-this-buffer)
(add-hook 'perl-mode-hook 'kreatv-copyright-activate-for-this-buffer)
(add-hook 'python-mode-hook 'kreatv-copyright-activate-for-this-buffer)
(add-hook 'sh-mode-hook 'kreatv-copyright-activate-for-this-buffer)

(provide 'kreatv-copyright)
