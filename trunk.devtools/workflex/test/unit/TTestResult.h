/*
 *--------------------------------------------------------------------
 *
 * test/TTestResult.h
 *
 * Unit test result class. Inspired by CppUnit.
 *
 * The extension to the original CppUnit framwork is
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#ifndef TEST_TTESTRESULT_H
#define TEST_TTESTRESULT_H

#include <string>

class TTestException;
class TTest;

/*
 * A TTestResult interface receives results of executing a test case.
 *
 * The test framework distinguishes between failures and errors.
 * A failure is anticipated and checked for with assertions. Errors are
 * unanticipated problems signified by exceptions that are not generated
 * by the framework.
 *
 * see TTest
 */

class TTestResult
{
public:
  virtual ~TTestResult()
  {
    // Empty.
  }

  virtual void Lock() = 0;
  virtual void Unlock() = 0;

  virtual void AddError(const TTest& test, const TTestException& e) = 0;
  virtual void AddFailure(const TTest& test, const TTestException& e) = 0;
  virtual void StartTest(const std::string& name) = 0;
  virtual void EndTest(const std::string& name) = 0;

  virtual bool ShouldStop() = 0;
};

#endif
