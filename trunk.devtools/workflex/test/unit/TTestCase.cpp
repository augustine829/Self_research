/*
 *--------------------------------------------------------------------
 *
 * test/TTestCase.cpp
 *
 * Unit test case class. Inspired by CppUnit.
 *
 * The extension to the original CppUnit framwork is
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#include "TTestCase.h"
#include "TTestResult.h"
#include <stdexcept>
#include <typeinfo>

#ifdef NO_SSTREAM_HEADER
// Support for the "old" C++ standard library.
#  include <strstream>
#  define ostringstream ostrstream
#  define istringstream istrstream
#else
#  include <sstream>
#endif

// All the work for RunTest is deferred to subclasses 
void TTestCase::RunTest()
{

}

// Check for a failed general assertion 
void TTestCase::AssertImplementation(bool condition,
                                     std::string conditionExpression,
                                     int lineNumber, std::string fileName)
{
  if (!condition) {
    throw TTestException(conditionExpression, lineNumber, fileName); 
  }
}

// Check for a failed equality assertion. This is just intended as a simple
// demo to show how customized messages can be applied.
void TTestCase::AssertEquals(int expected, int actual,
                             int lineNumber, std::string fileName)
{
  if (expected != actual) {
    std::ostringstream os;
    os << "Expected " << expected << " but was " << actual; 
    AssertImplementation(false, os.str(), lineNumber, fileName);
  }
}

// A hook for fixture set up
void TTestCase::SetUp()
{

}

// A hook for fixture tear down
void TTestCase::TearDown()
{

}

// Run the test and catch any exceptions that are triggered by it 
void TTestCase::Run(TTestResult* result)
{
  result->Lock();
  result->StartTest(GetInstanceName());
  result->Unlock();

  try {
    SetUp();

    try {
      RunTest();
    }
    catch (TTestException& e) {
      result->Lock();
      result->AddFailure(*this, e);
      result->Unlock();
    }
    catch (std::exception& e) {
      result->Lock();
      result->AddError(*this, TTestException(e.what()));
      result->Unlock();
    }
    catch (...) {
      result->Lock();
      result->AddError(*this, TTestException("unknown exception"));
      result->Unlock();
    }

    TearDown();
  }
  catch (std::exception& e) {
    result->Lock();
    result->AddError(*this, TTestException(std::string("Fixture error: ")
                                           + e.what()));
    result->Unlock();
  }
  catch (...) {
    result->Lock();
    result->AddError(*this, TTestException("Unknown fixture error"));
    result->Unlock();
  }

  result->Lock();
  result->EndTest(GetInstanceName());
  result->Unlock();
}

// Returns a count of all the tests executed
int TTestCase::CountTestCases() const
{
  return 1;
}

// Returns the name of the test case instance
std::string TTestCase::GetInstanceName() const
{
#ifdef _MSC_VER
  // (Win32 only) Turn off warning for 'typeid' used on polymorphic type
  // 'class TTestCase' with /GR-. Unpredictable behavior may result but
  // it seems to be resolved fine by the try-catch.
#  pragma warning( disable : 4541)
#endif

  std::string name = Name;
  /*try {
    const char* className = typeid(*this).name();

    // Remove any digits from the beginning of the name string.
    while ('0' <= *className && *className <= '9') {
      ++className;
    }

    name = className;
    name += "::";
    name += Name;
  }
  catch (...) {
    // If you end up here, RTTI is probably disabled.
    name = Name;
  }*/

  return name;
}
