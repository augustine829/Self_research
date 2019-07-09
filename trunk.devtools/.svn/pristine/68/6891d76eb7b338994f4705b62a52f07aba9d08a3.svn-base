/*
 *--------------------------------------------------------------------
 *
 * TMankanBuggTest.cpp
 *
 *--------------------------------------------------------------------
 */

#include "TMankanBuggTest.h"
#include "Parser.h"

#include <iostream>

void TMankanBuggTest::Test()
{
  try {
    TParser parser("test/mankanbugg.txt");
    parser.GetHeader();
    parser.GetTimeReport();
  }
  catch (TVerboseException& e) {
    std::cerr << e.GetText() << std::endl;
    TestAssert(false);
  }
}

TTest* TMankanBuggTest::GetSuite()
{
  TTestSuite* suite = new TTestSuite("TMankanBuggTest");
  suite->AddTest(ALLOC_CALLER(TMankanBuggTest, Test));
  return suite;
}
