;;; This file defines an Emacs cc-mode style called "kreatv" that follows the
;;; KreaTV coding standard.

(defun kreatv-cc-inside-class-enum-p (pos)
  "Checks if POS is within the braces of a C++ \"enum class\"."
  (ignore-errors
    (save-excursion
      (goto-char pos)
      (up-list -1)
      (looking-back "enum[ \t]+class[^}]+"))))

(defun kreatv-cc-align-enum-class (langelem)
  (if (kreatv-cc-inside-class-enum-p (c-langelem-pos langelem))
      0
    (c-lineup-topmost-intro-cont langelem)))

(defun kreatv-cc-align-enum-class-closing-brace (langelem)
  (if (kreatv-cc-inside-class-enum-p (c-langelem-pos langelem))
      '-
    '+))

(defun kreatv-cc-fix-enum-class ()
  (add-to-list 'c-offsets-alist
               '(topmost-intro-cont . kreatv-cc-align-enum-class))
  (add-to-list 'c-offsets-alist
               '(statement-cont . kreatv-cc-align-enum-class-closing-brace)))

(defun kreatv-cc-init-c++-mode ()
  (kreatv-cc-fix-enum-class)
  (setq c-label-minimum-indentation 0))

(add-hook 'c++-mode-hook 'kreatv-cc-init-c++-mode)

(c-add-style
 "kreatv"
 '("gnu"
   (indent-tabs-mode . nil)
   (c-basic-offset . 2)
   (c-block-comment-prefix . "* ")
   (c-hanging-colons-alist
    (case-label after)
    (label after))
   (c-cleanup-list
    empty-defun-braces
    defun-close-semi
    list-close-comma
    scope-operator)
   (c-hanging-semi&comma-criteria
    c-semi&comma-no-newlines-before-nonblanks
    c-semi&comma-no-newlines-for-oneline-inliners
    c-semi&comma-inside-parenlist)
   (c-offsets-alist
    (innamespace . 0)
    (inclass . +)
    (inline-open . 0)
    (statement-cont . +)
    (substatement-open . 0)
    (arglist-intro . +)
    (arglist-close . +))
   (c-hanging-braces-alist
    (substatement-open after)
    (defun-open before after)
    (class-open before after))))

(provide 'kreatv-cc-style)
