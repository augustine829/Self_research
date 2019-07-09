/*
 *--------------------------------------------------------------------
 *
 * test/console/TVerboseConsoleTestResult.cpp
 *
 * A more verbose version of TConsoleTestResult.
 *
 * Copyright (c) 2005 Kreatel Communications AB. All Rights Reserved.
 * Copyright (c) 2013 Motorola Mobility, Inc. All rights reserved.
 *
 * This program is confidential and proprietary to Motorola Mobility, Inc and
 * may not be copied, reproduced, disclosed to others, published or used, in
 * whole or in part, without the expressed prior written permission of Motorola
 * Mobility, Inc.
 *
 *--------------------------------------------------------------------
 */

#include "TVerboseConsoleTestResult.h"

#include <cstdio>


TVerboseConsoleTestResult::TVerboseConsoleTestResult()
  : VerboseFlag(true)
{
  // Empty
}

TVerboseConsoleTestResult::~TVerboseConsoleTestResult()
{
  // Empty
}

void TVerboseConsoleTestResult::SetVerbose(bool verboseFlag)
{
  VerboseFlag = verboseFlag;
}

void TVerboseConsoleTestResult::AddError(const TTest& test,
                                         const TTestException& e)
{
  TConsoleTestResult::AddError(test, e);
  if (VerboseFlag) {
    ::fprintf(stderr, "***** TEST ERROR HERE!!! *****\n");
    ::fflush(stderr);
  }
}

void TVerboseConsoleTestResult::AddFailure(const TTest& test,
                                           const TTestException& e)
{
  TConsoleTestResult::AddFailure(test, e);
  if (VerboseFlag) {
    ::fprintf(stderr, "***** TEST FAILURE HERE!!! *****\n");
    ::fflush(stderr);
  }
}

void TVerboseConsoleTestResult::StartTest(const std::string& name)
{
  TConsoleTestResult::StartTest(name);
  if (VerboseFlag) {
    LastErrorCounter = ErrorCounter;
    LastFailureCounter = FailureCounter;
    ::fprintf(stdout, "Running %s...\n", name.c_str());
    ::fflush(stdout);
  }
}

void TVerboseConsoleTestResult::EndTest(const std::string& name)
{
  if (VerboseFlag) {
    if (LastErrorCounter == ErrorCounter
        && LastFailureCounter == FailureCounter) {
      ::fprintf(stdout, "OK\n");
      ::fflush(stdout);
    }
  }
  TConsoleTestResult::EndTest(name);
}
