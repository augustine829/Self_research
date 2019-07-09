(require 'kreatel-c++-header-common "c++-header-common.el")

;;; ---------------------------------------------------------------------------
;;; Functions to create a TestMain.cpp

(defun kreatel-create-test-main ()
  (interactive)
  (progn
    (setq directory (file-name-as-directory
                     (concat (file-name-directory (buffer-file-name))
                             "testcases")))
    (setq filename (concat directory "TestMain.cpp"))
    (if (not (file-directory-p directory))
        (message (concat "The directory " directory " doesn't exist!"))
      (if (file-exists-p filename)
          (message "TestMain.cpp already exists!")
        (progn
          (switch-to-buffer (find-file-noselect filename))
          (goto-char (point-min))
          (kreatel-common-insert-header "TestMain.cpp"
                                        "Main function for running unit tests")
          (insert "#include \"testcases/T?Tests.h\"\n\n")
          (insert "#include \"debug/TStderrTracker.h\"\n")
          (insert "#include \"debug/TNullTracker.h\"\n")
          (insert "#include \"test/console/TVerboseConsoleTestResult.h\"\n\n")
          (insert "#define EXTRA_TEST_OUTPUT\n\n")
          (kreatel-separator)
          (insert "// Tracker\n\n")
          (insert "TTracker* TTracker::GetProcessTracker()\n")
          (insert "{\n")
          (insert "#ifdef EXTRA_TEST_OUTPUT\n")
          (insert "  static TStderrTracker tracker(TrackAll);\n")
          (insert "#else\n")
          (insert "  static TNullTracker tracker;\n")
          (insert "#endif\n")
          (insert "  return &tracker;\n")
          (insert "}\n\n")
          (kreatel-separator)
          (insert "// main\n\n")
          (insert "int main(int /*argc*/, char** /*argv*/)\n")
          (insert "{\n")
          (save-excursion
            (insert "  TTestSuite suite(?);\n")
            (insert "  suite.AddTest(T?Tests::GetSuite());\n\n")
            (insert "  TVerboseConsoleTestResult result;\n")
            (insert "#ifndef EXTRA_TEST_OUTPUT\n")
            (insert "  result.SetVerbose(false);\n")
            (insert "#endif\n")
            (insert "  suite.Run(&result);\n\n")
            (insert "  result.PrintSummary();\n")
            (insert "  return result.WasSuccessful() ? 0 : 1;\n")
            (insert "}\n"))
          (c++-mode))))))


;;; ---------------------------------------------------------------------------
;;; Functions to create test classes for a specific class.

(defun kreatel-create-test-h-file (buffername filename classname testclassname)
  (save-excursion
    (set-buffer buffername)
    (goto-char (point-min))
    (kreatel-common-insert-header filename (concat "Tests for " classname))
    (insert "#ifndef " (upcase testclassname) "_H\n")
    (insert "#define " (upcase testclassname) "_H\n\n")
    (insert "#include \"test/TTestCase.h\"\n")
    (insert "#include \"test/TMethodRecorder.h\"\n\n")
    (insert "class " testclassname " : public TTestCase\n")
    (insert "{\n")
    (insert "private:\n")
    (insert "  TMethodRecorder Recorder;\n\n")
    (insert "  void Test1();")
    (save-excursion
      (insert "\n\npublic:\n")
      (insert "  " testclassname "(const std::string& name);\n")
      (insert "  static TTest* GetSuite();\n")
      (insert "};\n\n")
      (insert "#endif\n"))
    (c++-mode)))


(defun kreatel-create-test-cpp-file (buffername cpp-file h-file
                                     classname testclassname)
  (save-excursion
    (set-buffer buffername)
    (goto-char (point-min))
    (kreatel-common-insert-header cpp-file (concat "Tests for " classname))
    (insert "#include \"testcases/" h-file "\"\n\n")
    (insert "#include \"" classname ".h\"\n\n")
    (insert "#include \"test/TTestSuite.h\"\n")
    (insert "#include \"test/TTestCaller.h\"\n\n\n")
    (kreatel-separator)
    (insert "// Private functions\n\n")
    (insert "void " testclassname "::Test1()\n")
    (insert "{\n")
    (insert "  // TODO")
    (save-excursion
      (insert "\n}\n\n\n")
      (kreatel-separator)
      (insert "// Public functions\n\n")
      (insert testclassname "::" testclassname "(const std::string& name)\n")
      (insert "  : TTestCase(name)\n")
      (insert "{\n")
      (insert "  // Empty\n")
      (insert "}\n\n")
      (insert "TTest* " testclassname "::GetSuite()\n")
      (insert "{\n")
      (insert "  TTestSuite* testSuite = new TTestSuite(\""
              testclassname "\");\n\n")
      (insert "  testSuite->AddTest(ALLOC_CALLER("
              testclassname ", Test1));\n")
      (insert "  return testSuite;\n")
      (insert "}\n"))
    (c++-mode)))


(defun kreatel-create-test-class ()
  (interactive)
  (let (classname pos testclassname directory
        h-file cpp-file h-buffer cpp-buffer)
    (setq classname (file-name-nondirectory (buffer-file-name)))
    (if (not (string-match "T.*\\.\\(h\\|cpp\\)" classname))
        (message "The class file must be named T<name>.h/cpp.")
      (progn
        (setq pos (string-match "\\." classname))
        (setq classname (substring classname 0 pos))
        (setq testclassname (concat (substring classname 0 pos) "Tests"))
        (setq directory (file-name-as-directory
                         (concat (file-name-directory (buffer-file-name))
                                 "testcases")))
        (if (not (file-directory-p directory))
            (message (concat "The directory " directory " doesn't exist!"))
          (progn
            (setq h-file (concat testclassname ".h"))
            (setq cpp-file (concat testclassname ".cpp"))
            (if (or (file-exists-p (concat directory h-file))
                    (file-exists-p (concat cpp-file)))
                (message "The test .h or .cpp-file already exists!")
              (progn
                (setq h-buffer (find-file-noselect (concat directory h-file)))
                (setq cpp-buffer (find-file-noselect
                                  (concat directory cpp-file)))
                (kreatel-create-test-h-file h-buffer h-file
                                            classname testclassname)
                (kreatel-create-test-cpp-file cpp-buffer cpp-file h-file
                                              classname testclassname)
                (switch-to-buffer h-buffer)))))))))


;;; ---------------------------------------------------------------------------
;;; Functions to create mock classes for a specific interface.

(defun kreatel-print-function-definitions (funlist)
  (if (not (null funlist))
      (progn
        (insert "  virtual " (cadr (car funlist)) ";\n")
        (kreatel-print-function-definitions (cdr funlist)))))


(defun kreatel-print-function-declarations (ifcname classname funlist)
  (let (returntype funstring)
    (if (not (null funlist))
        (progn
          (setq funstring (cadr (car funlist)))
          (string-match "\\(\\s \\|\\\n\\)+" funstring)
          (setq returntype (substring funstring 0 (match-end 0)))
          (setq funstring (substring funstring (match-end 0)))
          (insert "inline " returntype classname "::\n" funstring "\n")
          (insert "{\n")
          (insert "  Recorder.Push(\"" ifcname "::" (car (car funlist))
                  "()\");\n")
          (insert "}\n\n")
          (kreatel-print-function-declarations ifcname
                                               classname (cdr funlist))))))



(defun kreatel-create-mock-h-file (buffername filename ifcname mockclassname
                                   funlist)
  (save-excursion
    (set-buffer buffername)
    (goto-char (point-min))
    (kreatel-common-insert-header filename
                                  (concat "Mock class for interface " ifcname))
    (insert "#ifndef " (upcase mockclassname) "_H\n")
    (insert "#define " (upcase mockclassname) "_H\n\n")
    (insert "#include \"" ifcname ".h\"\n")
    (insert "#include \"test/TMethodRecorder.h\"\n\n")
    (insert "class " mockclassname " : public " ifcname "\n")
    (insert "{\n")
    (insert "private:\n")
    (insert "  TMethodRecorder& Recorder;\n\n")
    (insert "public:\n")
    (insert "  " mockclassname
            "(TMethodRecorder& recorder) throw ();\n\n")
    (kreatel-print-function-definitions funlist)
    (save-excursion
      (insert "};\n\n")
      (kreatel-separator)
      (insert "// Inlined functions\n\n")
      (insert "inline " mockclassname "::\n" mockclassname
              "(TMethodRecorder& recorder) throw ()\n")
      (insert "  : Recorder(recorder)\n")
      (insert "{\n")
      (insert "  // Empty\n")
      (insert "}\n\n")
      (kreatel-print-function-declarations ifcname mockclassname funlist)
      (insert "#endif\n"))
    (c++-mode))
  (switch-to-buffer h-buffer))


(defun kreatel-parse-ifc-functions (ifcname)
  (let ((functions nil)
        endpos
        nextstartpos
        tmppos
        funstring)
    (save-excursion
      (goto-char (point-min))
      (if (not (re-search-forward
                (concat "class\\(\\s \\|\n\\)+" ifcname
                        "\\(\\s \\|\n\\)*{\\(\\s \\|\n\\)*"
                        "public:\\(\\s \\|\n\\)*") nil t))
          (message (concat "Could not find interface " ifcname "."))
        (while (re-search-forward
                "\\(\\s \\|\n\\)*=\\(\\s \\|\n\\)*0\\(\\s \\|\n\\)*;"
                nil t)
          (setq endpos (match-beginning 0))
          (setq nextstartpos (match-end 0))
          (if (re-search-backward "virtual\\(\\s \\|\n\\)+")
              (progn
                (setq funstring (buffer-substring (match-end 0) endpos))
                (if (string-match "\\sw+\\*?\\(\\s \\|\n\\)*" funstring)
                    (progn
                      (setq tmppos (match-end 0))
                      (if (string-match "\\sw+\\(\\s \\|\n\\)*\("
                                        funstring tmppos)
                          (progn
                            (message funstring)
                            (setq functions
                                  (cons (list (substring funstring tmppos
                                                       (- (match-end 0) 1))
                                              funstring)
                                        functions))))))))
          (goto-char nextstartpos)))
      (reverse functions))))


(defun kreatel-create-mock-class ()
  (interactive)
  (let (ifcname mockclassname directory h-file h-buffer funlist)
    (setq ifcname (file-name-nondirectory (buffer-file-name)))
    (if (not (string-match "I\\sw*\\.h" ifcname))
        (message "The interface file must be named I<name>.h.")
      (progn
        (setq ifcname (substring ifcname 0 (- (match-end 0) 2)))
        (setq mockclassname (concat "TMock" (substring ifcname 1)))
        (setq directory (file-name-as-directory
                         (concat (file-name-directory (buffer-file-name))
                                 "testcases")))
        (if (not (file-directory-p directory))
            (message (concat "The directory " directory " doesn't exist!"))
          (progn
            (setq h-file (concat mockclassname ".h"))
            (if (file-exists-p (concat directory h-file))
                (message ("The mock class .h-file already exists!"))
              (progn
                (setq funlist (kreatel-parse-ifc-functions ifcname))
                (if (not (null funlist))
                    (progn
                      (setq h-buffer (find-file-noselect
                                      (concat directory h-file)))
                      (kreatel-create-mock-h-file h-buffer h-file ifcname
                                                  mockclassname funlist)
                      (switch-to-buffer h-buffer) ))))))))))


;;; ---------------------------------------------------------------------------

(provide 'kreatel-unit-test)
