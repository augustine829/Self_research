/*
 *--------------------------------------------------------------------
 *
 * test/TTestCaller.h
 *
 * Unit test caller class. Inspired by CppUnit.
 *
 * The extension to the original CppUnit framwork is
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#ifndef TEST_TESTCALLER_H
#define TEST_TESTCALLER_H

#include "TTestCase.h"
#include <memory>  // Defines auto_ptr template.

/* 
 * A test caller provides access to a test case method on a test case
 * class. Test callers are useful when you want to run an individual
 * test or add it to a suite.
 * 
 * Here is an example:
 * 
 * class TMathTest : public TTestCase
 * {
 *   ...
 * public:
 *   void SetUp();
 *   void TearDown();
 *
 *   void TestAdd();
 *   void TestSubtract();
 * };
 *
 * TTest* TMathTest::Suite()
 * {
 *   TTestSuite* suite = new TTestSuite;
 *   suite->AddTest(new TestCaller<TMathTest>("TestAdd", TestAdd));
 *   return suite;
 * }
 *
 * You can use a TTestCaller to bind any test method on a TTestCase
 * class, as long as it returns accepts void and returns void.
 * 
 * See TTestCase
 */

#define ALLOC_CALLER(classname, funcname) (new TTestCaller< classname >( #classname "::" #funcname , & classname :: funcname))


template <class TFixture>
class TTestCaller : public TTestCase
{ 
  typedef void (TFixture::*TTestMethod)();

private:
  std::auto_ptr<TFixture> Fixture;
  TTestMethod Test;

  TTestCaller(const TTestCaller& other);
  TTestCaller& operator=(const TTestCaller& other); 

public:
  TTestCaller(const std::string& name, TTestMethod test);

protected:
  virtual void SetUp();
  virtual void TearDown();

  virtual void RunTest();
  virtual std::string GetInstanceName() const;
};

template <class TFixture>
inline TTestCaller<TFixture>::TTestCaller(const std::string& name,
                                          TTestMethod test)
  : TTestCase(name),
    Fixture(new TFixture(name)),
    Test(test)
{
  // Empty.
}

template <class TFixture>
void TTestCaller<TFixture>::SetUp()
{
  Fixture->SetUp();
}

template <class TFixture>
void TTestCaller<TFixture>::TearDown()
{
  Fixture->TearDown();
}

template <class TFixture>
void TTestCaller<TFixture>::RunTest() 
{
  // ->* operator is not supported directly by std::auto_ptr.
  ((Fixture.get())->*Test)();
}

template <class TFixture>
std::string TTestCaller<TFixture>::GetInstanceName() const
{
  return Fixture->GetInstanceName();
}

#endif
