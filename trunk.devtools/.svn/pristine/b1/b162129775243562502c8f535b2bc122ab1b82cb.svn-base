/*
 *--------------------------------------------------------------------
 *
 * test/TTestCase.h
 *
 * Unit test case class. Inspired by CppUnit.
 *
 * The extension to the original CppUnit framwork is
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#ifndef TEST_TTESTCASE_H
#define TEST_TTESTCASE_H

#include "TTest.h"
#include "TTestException.h"
#include <string>

class TTestResult;

/*
 * A test case defines the fixture to run multiple tests. To define
 * a test case:
 *
 * 1) implement a subclass of TTestCase
 * 2) define instance variables that store the state of the fixture
 * 3) initialize the fixture state by overriding SetUp()
 * 4) clean-up after a test by overriding TearDown().
 *
 * Each test runs in its own fixture so there can be no side effects
 * among test runs. Here is an example:
 * 
 * class TMathTest : public TTestCase
 * {
 *   protected:
 *     int m_value1;
 *     int m_value2;
 *
 *   public:
 *     TMathTest(std::string name)
 *       : TTestCase(name) { }
 *
 *   protected:
 *     void SetUp()
 *     {
 *       Value1 = 2;
 *       Value2 = 3;
 *     }
 * };
 *
 * For each test implement a method which interacts with the fixture.
 * Verify the expected results with assertions specified by calling
 * Assert() on the expression you want to test:
 * 
 *  protected:
 *    void TestAdd()
 *    {
 *      int result = value1 + value2;
 *      Assert(result == 5);
 *    }
 * 
 * Once the methods are defined you can run them. To do this, use
 * a TTestCaller.
 *
 * TTest* test = new TTestCaller<MathTest>("testAdd", TMathTest::testAdd);
 * test->Run();
 *
 * The tests to be run can be collected into a TTestSuite. The framework
 * provides different test runners which can run a test suite and collect
 * the results. The test runners expect a static method suite as the entry
 * point to get a test to run.
 * 
 * public:
 *   static TMathTest::Suite()
 *   {
 *     TTestSuite* suiteOfTests = new TTestSuite;
 *     suiteOfTests->AddTest(new TTestCaller<TMathTest>("TestAdd", TestAdd));
 *     suiteOfTests->AddTest(new TTestCaller<TMathTest>("TestDivideByZero",
 *                                                       TestDivideByZero));
 *     return suiteOfTests;
 *   }
 * 
 * Note that the caller of suite assumes lifetime control for the
 * returned suite.
 *
 * see TTestResult, TTestSuite and TTestCaller
 */

class TTestCase : public TTest
{
private:
  const std::string Name;

  TTestCase(const TTestCase& other);
  TTestCase& operator =(const TTestCase& other);

protected:
  virtual void RunTest();
 
  void AssertImplementation(bool condition,
                            std::string conditionExpression = "",
                            int lineNumber = TEST_UNKNOWN_LINE_NUMBER,
                            std::string fileName = TEST_UNKNOWN_FILENAME);
 
  void AssertEquals(int expected, int actual,
                    int lineNumber = TEST_UNKNOWN_LINE_NUMBER,
                    std::string fileName = TEST_UNKNOWN_FILENAME);

public:
  TTestCase(const std::string& name);
  ~TTestCase();

  virtual void SetUp();
  virtual void TearDown();

  // TTest interface:
  virtual void Run(TTestResult *result);
  virtual int CountTestCases() const;
  virtual std::string GetInstanceName() const;
};

// Constructs a test case
inline TTestCase::TTestCase(const std::string& name) 
  : Name(name) 
{

}

// Destructs a test case
inline TTestCase::~TTestCase()
{

}

// A set of macros which allow us to get the line number
// and file name at the point of an error.
// Just goes to show that preprocessors do have some redeeming qualities.

#define TEST_SOURCE_ANNOTATION

#ifdef TEST_SOURCE_ANNOTATION

#undef TestAssert
#define TestAssert(condition) (this->AssertImplementation((condition), (#condition), __LINE__, __FILE__))

#else

#undef TestAssert
#define TestAssert(condition) (this->AssertImplementation((condition), "", __LINE__, __FILE__))

#endif

#endif  // TEST_TTESTCASE_H
