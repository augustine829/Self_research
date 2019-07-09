/*
 *--------------------------------------------------------------------
 *
 * test/TTest.h
 *
 * Unit test class. Inspired by CppUnit.
 *
 * The extension to the original CppUnit framework is
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#ifndef TEST_TTEST_H
#define TEST_TTEST_H

#include <string>

class TTestResult;

/*
 * A TTest is an abstract class.
 *
 * See TTestResult.
 */

class TTest
{
public:
  // A virtual destructor helps preventing some common resource
  // management errors.
  virtual ~TTest()
  {
    // Empty.
  }

  // Runs this test and collects its result in a TTestResult instance.
  virtual void Run(TTestResult* result) = 0;

  // Counts the number of test cases that will be run by this test.
  virtual int CountTestCases() const = 0;

  // Returns the name of this specific test instance. 
  virtual std::string GetInstanceName() const = 0;
};

#endif
