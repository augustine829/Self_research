/*
 *--------------------------------------------------------------------
 *
 * test/console/TVerboseConsoleTestResult.h
 *
 * A more verbose version of TConsoleTestResult.
 * 
 * Copyright (c) 2005 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#ifndef TEST_VERBOSE_TVERBOSECONSOLETESTRESULT_H
#define TEST_VERBOSE_TVERBOSECONSOLETESTRESULT_H

#include "TConsoleTestResult.h"

class TVerboseConsoleTestResult : public TConsoleTestResult
{
protected:
  uint32_t LastErrorCounter;
  uint32_t LastFailureCounter;

  bool VerboseFlag;

public:
  TVerboseConsoleTestResult();
  virtual ~TVerboseConsoleTestResult();

  void SetVerbose(bool verboseFlag);

  virtual void AddError(const TTest& test, const TTestException& e);
  virtual void AddFailure(const TTest& test, const TTestException& e);
  virtual void StartTest(const std::string& name);
  virtual void EndTest(const std::string& name);
};

#endif
