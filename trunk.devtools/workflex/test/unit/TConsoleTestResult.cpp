/*
 *--------------------------------------------------------------------
 *
 * test/console/TConsoleTestResult.cpp
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

#include "TConsoleTestResult.h"
#include "TTest.h"

#include <cstdio>


void TConsoleTestResult::PrintSummary()
{
  ::fprintf(stdout, "Test Result: ");

  if (TestsStarted == TestsEnded
      && ErrorCounter == 0
      && FailureCounter == 0) {
    ::fprintf(stdout, "SUCCESS! (All %u tests completed successfully)\n",
              TestsEnded);
  }
  else if (TestsStarted != TestsEnded) {
    ::fprintf(stdout, "Tests started differs from tests ended.\n");
  }
  else {
    ::fprintf(stdout, "OK: %u  Errors: %u  Failures %u\n",
              (TestsEnded - ErrorCounter - FailureCounter),
              ErrorCounter, FailureCounter);
  }
  ::fflush(stdout);
}

void TConsoleTestResult::Lock()
{
  // Empty
}

void TConsoleTestResult::Unlock()
{
  // Empty
}

void TConsoleTestResult::PrintDetails(const TTestException& e)
{
  ::fprintf(stderr, "%s (%d): %s",
            e.GetFileName().c_str(), e.GetLineNumber(), e.GetDescription());
}

void TConsoleTestResult::AddError(const TTest& test, const TTestException& e)
{
  ++ErrorCounter;
  ::fprintf(stderr, "%s:\n", test.GetInstanceName().c_str());
  ::fprintf(stderr, "Error: ");
  PrintDetails(e);
  ::fprintf(stderr, "\n");
  ::fflush(stderr);
}

void TConsoleTestResult::AddFailure(const TTest& test, const TTestException& e)
{
  ++FailureCounter;
  ::fprintf(stderr, "%s:\n", test.GetInstanceName().c_str());
  ::fprintf(stderr, "Failure: ");
  PrintDetails(e);
  ::fprintf(stderr, "\n");
  ::fflush(stderr);
}

void TConsoleTestResult::StartTest(const std::string& /*name*/)
{
  ++TestsStarted;
}

void TConsoleTestResult::EndTest(const std::string& /*name*/)
{
  ++TestsEnded;
}

bool TConsoleTestResult::ShouldStop()
{
  return false;
}
