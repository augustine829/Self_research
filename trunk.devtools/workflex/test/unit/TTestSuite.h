/*
 *--------------------------------------------------------------------
 *
 * test/TTestSuite.h
 *
 * Unit test suite class. Inspired by CppUnit.
 *
 * The extension to the original CppUnit framwork is
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#ifndef TEST_TTESTSUITE_H
#define TEST_TTESTSUITE_H

#include "TTest.h"

#include <vector>
#include <string>

class TTestResult;

/*
 * A TTestSuite is a composite of TTests.
 * It runs a collection of test cases. Here is an example.
 * 
 * TTestSuite* suite = new TTestSuite();
 * suite->AddTest(new TTestCaller<MathTest>("TestAdd", TestAdd));
 * suite->AddTest(new TTestCaller<MathTest>("TestDivideByZero",
 *                                          TestDivideByZero));
 *
 * Note that TTestSuites assume lifetime control for any tests
 * added to them.
 *
 * see TTest and TTestCaller
 */

class TTestSuite : public TTest
{
private:
  TTestSuite(const TTestSuite& other);
  TTestSuite& operator =(const TTestSuite& other);

protected:
  std::vector<TTest*> Tests;
  const std::string Name;

public:
  TTestSuite(const std::string& name);
  ~TTestSuite();

  virtual void Run(TTestResult* result);
  virtual int CountTestCases() const;
  virtual std::string GetInstanceName() const;

  void AddTest(TTest* test);
  virtual void DeleteContents();
};

// Default constructor
inline TTestSuite::TTestSuite(const std::string& name)
  : Name(name)
{

}

// Destructor
inline TTestSuite::~TTestSuite()
{
  DeleteContents();
}

// Adds a test to the suite.
inline void TTestSuite::AddTest(TTest* test)
{
  Tests.push_back(test);
}

#endif
