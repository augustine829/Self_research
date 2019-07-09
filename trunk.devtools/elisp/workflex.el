;;; Flex-junk.

;; Följande tangentbindningar görs:
;;
;; (global-set-key [f4] 'flex-add)
;; (global-set-key [S-f4] 'flex-add-2)
;; (global-set-key [C-f4] 'flex-process-current)
;; (global-set-key [M-f4] 'flex-process-last)
;;
;; Några variabler som man kanske vill ändra:
;;
;; flex-dir
;;   Katalogen där flexfiler sparas. Måste sättas.
;;
;; flex-name
;;   Ditt namn. Måste sättas.
;;
;; flex-filename-format
;;   Anger format på filnamnet på en flexfil. Default är "flex-%B-%Y"
;;   där %B och %Y expanderas till månadsnamn respektive år.
;;
;; flex-filename-downcase
;;   Om sann, se till att filnamnet endast blir gemener.
;;
;; flex-use-select-type
;;   Om sann, välj typ (normaltid, sjukdom osv) vid varje inmatning.
;;
;; flex-use-select-activity
;;   Om sann, välj aktivitet vid varje inmatning. Annars används
;;   flex-default-activity.
;;
;; flex-auto-save
;;   Huruvida flexfilen ska sparas automatiskt efter tryck på F4.
;;
;; Exempel på hur det kan se ut i .emacs:
;;
;; (require 'workflex "/home/tools/elisp/workflex.el")
;; (setq flex-name "Foo Barsson")
;; (setq flex-dir "~/doc")
;; (setq flex-filename-format "flex-%B-%Y.txt")
;; (setq flex-filename-downcase t)
;; (setq flex-auto-save t)
;; (setq flex-use-select-activity t)

(defvar flex-name "*flex-name*")

(defvar flex-activities
  '(("Generellt" . "GEN")
    ("Utveckling Generellt" . "UTV.GEN")
    ("HAI/HAL 2.0" . "HAL20")))

(defvar flex-types
  '(("normaltid" . "n") ("restid" . "r") ("övertid1" . "ö1")
    ("övertid2" . "ö2") ("semester" . "s") ("sjukdom" . "sj")
    ("permission" . "p")))

(defvar flex-result "*flex-result*")
(defvar flex-filename-format "flex-%B-%Y"
  "Se dokumentationen till format-time-string")
(defvar flex-filename-downcase t)
(defvar flex-newline-between-days t)
(defvar flex-command "/home/tools/devtools/trunk/bin/workflex")
(defvar flex-dir)
(defvar flex-default-activity "UTV.GEN")
(defvar flex-type "n")
(defvar flex-use-select-type nil)
(defvar flex-use-select-activity t)
(defvar flex-auto-save nil
  "*Huruvida flextidsfilen ska sparas automatiskt")

; Internal
(defvar flex-activity)

(defun flex-header ()
  (interactive)
  (let* ((date (decode-time))
         (summary (condition-case nil
                      (flex-get-summary (flex-last-filename))
                    (error nil)))
         (inflex    (flex-get-summary-time-value 'flex-balance summary))
         (komp      (flex-get-summary-time-value 'komp-balance summary))
         (overtime1 (flex-get-summary-time-value 'overtime1-balance summary))
         (overtime2 (flex-get-summary-time-value 'overtime2-balance summary)))
    (insert (format
             (concat
              "namn = %s\n"
              "år = %4d\n"
              "månad = %02d\n"
              (format "inflex = %s\n" inflex)
              "komptidsuttag = 0:00\n"
              (format "ingående komptid = %s\n" komp)
              (format "ingående övertid1 = %s\n" overtime1)
              (format "ingående övertid2 = %s\n" overtime2)
              "övertid i pengar = ja")
             flex-name (nth 5 date) (nth 4 date)))))

(defun flex-last-filename ()
  (expand-file-name
   (let ((time (decode-time (current-time)))
         (name))
     (setcar (nthcdr 4 time) (- (nth 4 time) 1))
     (setq name (format-time-string
                 flex-filename-format
                 (apply 'encode-time time)))
     (if flex-filename-downcase
         (downcase name)
       name))
   flex-dir))

(defun flex-filename ()
  (expand-file-name
   (let ((name (format-time-string flex-filename-format)))
     (if flex-filename-downcase
         (downcase name)
       name))
   flex-dir))

(defun flex-open-file (path)
  (let* ((filename (file-name-nondirectory path))
         (buffer (get-buffer filename)))
    (if buffer
        (pop-to-buffer buffer)
      (find-file path)
      (goto-char (point-max)))))

(defun flex-last-date ()
  (save-excursion
    (beginning-of-line)
    (while (progn (forward-line -1) (or (= (following-char) ?\ )
                                        (= (following-char) ?\n))))
    (forward-char 8)
    (+ (* 10 (- (char-after (point)) ?0)) (- (char-after (+ (point) 1)) ?0))))

(defun flex-whitespace-p (ch)
  (and (not (null ch))
       (or (= ch ?\ )
           (= ch ?\n)
           (= ch ?\t))))

(defun flex-remove-whitespace ()
  (goto-char (point-max))
  (while (flex-whitespace-p (char-before))
    (delete-char -1)))

(defun flex-add ()
  (interactive)
  (flex-open-file (flex-filename))
  (flex-remove-whitespace)
  (when (= (point-max) (point-min))
    (flex-header))
  (let ((date (decode-time)))
    (if (and (= (point) (+ (point-at-bol 21)))
             (= (char-before) ?-))
        ;; Ongoing activity: add stop.
        (progn (when flex-use-select-type
                 (flex-select-type))
               (flex-select-activity)
               (flex-add-stop))
      ;; New activity: add start.
      (progn (insert "\n")
             (if (and flex-newline-between-days
                      (not (= (nth 3 date) (flex-last-date))))
                 (insert "\n"))
             (flex-add-start))))
  (when flex-auto-save
    (save-buffer)))

(defun flex-add-2 ()
  (interactive)
  (flex-add)
  (flex-add))

(defun flex-add-start ()
  (interactive)
  (let ((date (decode-time))
        (daynames '("sön" "mån" "tis" "ons" "tor" "fre" "lör")))
    (insert (format "%4d-%02d-%02d %3s %02d:%02d-"
                    (nth 5 date) (nth 4 date) (nth 3 date)
                    (nth (nth 6 date) daynames)
                    (nth 2 date) (nth 1 date)))))

(defun flex-add-stop ()
  (interactive)
  (let ((date (decode-time)))
    (insert (format "%02d:%02d %2s %s "
                    (nth 2 date) (nth 1 date) flex-type flex-activity))))

(defun flex-act-num (act)
  (cdr (assoc-ignore-case act flex-activities)))

(defun flex-num-act-h (act l)
  ; no rassq for strings!
  (cond ((null l) nil)
        ((string= (cdar l) act) (caar l))
        (t (flex-num-act-h act (cdr l)))))

(defun flex-num-act (act)
  (flex-num-act-h act flex-activities))

(defun flex-select-activity ()
  (interactive)
  (when flex-use-select-activity
    (let ((activity
           (completing-read
            (concat "Aktivitet: ("
                    (flex-num-act flex-default-activity) ") ")
            flex-activities nil t)))
      (when (zerop (length activity))
        (setq activity (flex-num-act flex-default-activity)))
      (setq flex-default-activity (flex-act-num activity))))
  (setq flex-activity flex-default-activity))

(defun flex-select-type ()
  (interactive)
  (setq flex-type
        (cdr (assoc
              (completing-read "Typ: (normaltid) " flex-types nil t)
              flex-types)))
  (when (zerop (length flex-type))
    (setq flex-type "n")))

(defun flex-process-into-buffer (path)
  (erase-buffer)
  (call-process (expand-file-name flex-command) nil t t path)
  (goto-char (point-min)))

(defun flex-process (path)
  (pop-to-buffer (get-buffer-create flex-result))
  (flex-process-into-buffer path))

(defun flex-process-last ()
  (interactive)
  (flex-process (flex-last-filename)))

(defun flex-process-current ()
  (interactive)
  (let ((tmpfile (make-temp-file "workflex-tmp-")))
    (flex-open-file (flex-filename))
    (goto-char (point-max))
    (flex-remove-whitespace)
    (save-buffer)
    (let ((region-end
           (progn
             (save-excursion
               (when (= (char-before) ?-)
                 ;; Skip unfinished last row.
                 (beginning-of-line))
               (point)))))
      (write-region (point-min) region-end tmpfile)
      (flex-process tmpfile)
      (delete-file tmpfile))))

(defun flex-parse-hh:mm (time)
  "Parses a time string on the format (-)HH:MM and returns the
time in minutes."
  (save-match-data
    (string-match "\\(-?\\)\\([0-9]+\\):\\([0-9]+\\)" time)
    (let ((sign (if (string= "-" (match-string 1 time)) -1 1))
          (hh (string-to-number (match-string 2 time)))
          (mm (string-to-number (match-string 3 time))))
      (* sign (+ (* 60 hh) mm)))))

(defun flex-format-time (minutes)
  (let ((am (abs minutes)))
    (format "%s%d:%02d"
            (if (< minutes 0) "-" "")
            (/ am 60)
            (% am 60))))

(defun flex-find-in-buffer (regexp groups)
  (save-excursion
    (save-match-data
      (goto-char (point-min))
      (if (search-forward-regexp regexp nil 'noerror)
          (let ((i groups)
                return-value)
            (while (> i 0)
              (push (match-string i) return-value)
              (setq i (1- i)))
            (if (= groups 1)
                (car return-value)
              return-value))
        nil))))

(defun flex-get-summary-from-current-buffer ()
  "Parses the current buffer containing output from the workflex
command and returns a summary. See `flex-get-summary'."
  (let* ((current-date (format-time-string "%Y-%m-%d"))
         (today-data-result
          (flex-find-in-buffer
           (concat
            (format "^ %s     " current-date)
            "\\([0-9][0-9]:[0-9][0-9]\\) *"   ; Total
            "\\(-?[0-9][0-9]:[0-9][0-9]\\) *" ; Flex
            "\\([0-9][0-9]:[0-9][0-9]\\) *"   ; Normal
            "\\([0-9][0-9]:[0-9][0-9]\\) *"   ; Övertid1
            "\\([0-9][0-9]:[0-9][0-9]\\)"     ; Övertid2
            )
           5))
         (today-data (if (null today-data-result)
                         '("00:00" "00:00" "00:00" "00:00" "00:00")
                       today-data-result))
         (flex-today (flex-parse-hh:mm (nth 1 today-data)))
         (overtime1-today (flex-parse-hh:mm (nth 3 today-data)))
         (overtime2-today (flex-parse-hh:mm (nth 4 today-data)))
         (flex-balance
          (- (flex-parse-hh:mm
              (flex-find-in-buffer
               "^[ *]Flexsaldo: *\\(-?[0-9][0-9]:[0-9][0-9]\\)" 1))
             flex-today))
         (komp-balance
          (- (flex-parse-hh:mm
              (flex-find-in-buffer
               "^[ *]Kompsaldo: *\\(-?[0-9][0-9]:[0-9][0-9]\\)" 1))
             flex-today))
         (overtime1-balance
          (- (flex-parse-hh:mm
              (flex-find-in-buffer
               "^[ *]Saldo för övertid1: *\\([0-9][0-9]:[0-9][0-9]\\)" 1))
             overtime1-today))
         (overtime2-balance
          (- (flex-parse-hh:mm
              (flex-find-in-buffer
               "^[ *]Saldo för övertid2: *\\([0-9][0-9]:[0-9][0-9]\\)" 1))
             overtime2-today)))
  (list (cons 'flex-balance flex-balance)
        (cons 'komp-balance komp-balance)
        (cons 'overtime1-balance overtime1-balance)
        (cons 'overtime2-balance overtime2-balance)
        (cons 'flex-today flex-today)
        (cons 'overtime1-today overtime1-today)
        (cons 'overtime2-today overtime2-today))))

(defun flex-get-summary (path)
  "Parses a flex file and returns an alist. The keys of the alist
are flex-balance, komp-balance, overtime1-balance,
overtime2-balance, flex-today, overtime1-today and
overtime2-today; the values are minutes. flex-balance,
overtime1-balance and overtime2-balance do not include today's
time."
  (with-temp-buffer
    (flex-process-into-buffer path)
    (flex-get-summary-from-current-buffer)))

(defun flex-get-summary-time-value (key summary)
  (if (null summary)
      ""
    (flex-format-time (cdr (assoc key summary)))))

;;; ---------------------------------------------------------------------------

(global-set-key [f4] 'flex-add)
(global-set-key [S-f4] 'flex-add-2)
(global-set-key [C-f4] 'flex-process-current)
(global-set-key [M-f4] 'flex-process-last)

(provide 'workflex)
