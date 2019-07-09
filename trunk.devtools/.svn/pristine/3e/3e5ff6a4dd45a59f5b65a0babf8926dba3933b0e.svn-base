/*
 *--------------------------------------------------------------------
 *
 * TestMain.cpp
 *
 * Main function for running unit tests.
 *
 * Copyright (c) 2006 Motorola, Inc. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#include "TMankanBuggTest.h"

#include "unit/TTestSuite.h"
#include "unit/TVerboseConsoleTestResult.h"

#define EXTRA_TEST_OUTPUT

// ----------------------------------------------------------------------------
// main

int main(int /*argc*/, char** /*argv*/)
{
  TTestSuite suite("Workflex");
  suite.AddTest(TMankanBuggTest::GetSuite());

  TVerboseConsoleTestResult result;
#ifndef EXTRA_TEST_OUTPUT
  result.SetVerbose(false);
#endif
  suite.Run(&result);

  result.PrintSummary();
  return result.WasSuccessful() ? 0 : 1;
}
