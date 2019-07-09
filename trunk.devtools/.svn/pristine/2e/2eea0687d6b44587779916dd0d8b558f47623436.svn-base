/*
 *--------------------------------------------------------------------
 *
 * test/console/TConsoleTestResult.h
 *
 * Unit test result class with results on standard output/error.
 *
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 * Copyright (c) 2013 Motorola Mobility, Inc. All rights reserved.
 *
 * This program is confidential and proprietary to Motorola Mobility, Inc and
 * may not be copied, reproduced, disclosed to others, published or used, in
 * whole or in part, without the expressed prior written permission of Motorola
 * Mobility, Inc.
 *
 *--------------------------------------------------------------------
 */

#ifndef TEST_CONSLOLE_TCONSOLETESTRESULT_H
#define TEST_CONSLOLE_TCONSOLETESTRESULT_H

#include "TTestResult.h"
#include "TTestException.h"
#include <stdint.h>

class TConsoleTestResult: public TTestResult
{
protected:
  uint32_t TestsStarted;
  uint32_t TestsEnded;
  uint32_t ErrorCounter;
  uint32_t FailureCounter;

  void PrintDetails(const TTestException& e);

public:
  TConsoleTestResult();
  virtual ~TConsoleTestResult();
  
  void PrintSummary();
  bool WasSuccessful();

  // TTestResult interface
  virtual void Lock();
  virtual void Unlock();

  virtual void AddError(const TTest& test, const TTestException& e);
  virtual void AddFailure(const TTest& test, const TTestException& e);
  virtual void StartTest(const std::string& name);
  virtual void EndTest(const std::string& name);

  virtual bool ShouldStop();
};

inline TConsoleTestResult::TConsoleTestResult()
  : TestsStarted(0),
    TestsEnded(0),
    ErrorCounter(0),
    FailureCounter(0)
{
  // Empty
}
inline TConsoleTestResult::~TConsoleTestResult()
{
  // Empty
}

inline bool TConsoleTestResult::WasSuccessful()
{
  return ErrorCounter == 0 && FailureCounter == 0;
}

#endif
