/*
 *--------------------------------------------------------------------
 *
 * test/TTestException.h
 *
 * Unit test exception class. Inspired by CppUnit.
 *
 * The extension to the original CppUnit framwork is
 * Copyright (c) 2001 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#ifndef TEST_TTESTEXCEPTION_H
#define TEST_TTESTEXCEPTION_H

/* 
 * TestException is an exception that serves
 * descriptive strings through its GetText() method
 */

#include <exception>
#include <string>

#define TEST_UNKNOWN_FILENAME "<unknown>"
#define TEST_UNKNOWN_LINE_NUMBER (-1)

class TTestException : public std::exception
{
private:
  std::string Message;
  int LineNumber;
  std::string FileName;

public:
  TTestException(std::string message = "", 
                 int lineNumber = TEST_UNKNOWN_LINE_NUMBER, 
                 std::string fileName = TEST_UNKNOWN_FILENAME) throw ();
  TTestException(const char* message,
                 int lineNumber = TEST_UNKNOWN_LINE_NUMBER, 
                 std::string fileName = TEST_UNKNOWN_FILENAME) throw ();
  TTestException(const TTestException& other) throw ();
  
  virtual ~TTestException() throw ();
  
  TTestException& operator =(const TTestException& other) throw ();
 
  const char* GetDescription() const throw ();
  int GetLineNumber() const throw ();
  std::string GetFileName() const throw ();
};

// Construct the exception
inline TTestException::TTestException(const TTestException& other) throw ()
  : exception(other)
{ 
  Message = other.Message; 
  LineNumber = other.LineNumber;
  FileName = other.FileName;
} 

inline TTestException::TTestException(std::string message,
                                      int lineNumber,
                                      std::string fileName) throw ()
  : Message(message),
    LineNumber(lineNumber),
    FileName(fileName)
{

}

inline TTestException::TTestException(const char* message,
                                      int lineNumber,
                                      std::string fileName) throw ()
  : LineNumber(lineNumber),
    FileName(fileName)
{
  if (message != NULL) {
    Message = message;
  }
}


// Destruct the exception
inline TTestException::~TTestException() throw ()
{

}

// Perform an assignment
inline TTestException& TTestException::operator =(const TTestException& other)
  throw ()
{ 
  exception::operator =(other);

  if (&other != this) {
    Message = other.Message; 
    LineNumber = other.LineNumber;
    FileName = other.FileName;
  }
  return *this; 
}

// Return descriptive message
inline const char *TTestException::GetDescription() const throw ()
{
  return Message.c_str();
}

// The line on which the error occurred
inline int TTestException::GetLineNumber() const throw ()
{
  return LineNumber;
}

// The file in which the error occurred
inline std::string TTestException::GetFileName() const throw ()
{
  return FileName;
}

#endif
