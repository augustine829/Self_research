/*
 *--------------------------------------------------------------------
 *
 * test/TTestSuite.cpp
 *
 * Unit test suite class. Inspired by CppUnit.
 *
 * The extension to the original CppUnit framwork is
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#include "TTestSuite.h"
#include "TTestResult.h"

// Deletes all tests in the suite.
void TTestSuite::DeleteContents()
{
  for (std::vector<TTest*>::iterator it = Tests.begin();
       it != Tests.end();
       ++it) {
    delete *it;
  }
}

// Runs the tests and collects their result in a TestResult.
void TTestSuite::Run(TTestResult* result)
{
  for (std::vector<TTest*>::iterator it = Tests.begin();
       it != Tests.end();
       ++it) {
    result->Lock();
    bool stopFlag = result->ShouldStop();
    result->Unlock();
    if (stopFlag) {
      break;
    }
    TTest* test = *it;
    test->Run(result);
  }
}

// Counts the number of test cases that will be run by this test.
int TTestSuite::CountTestCases() const
{
  int count = 0;

  for (std::vector<TTest*>::const_iterator it = Tests.begin();
       it != Tests.end();
       ++it) {
    count += (*it)->CountTestCases();
  }
  return count;
}

// Returns the name of the test case instance.
std::string TTestSuite::GetInstanceName() const
{
  return std::string("Suite ") + Name;
}
