/*
 *--------------------------------------------------------------------
 *
 * base/VerboseException.h
 *
 * An exception class with verbose exception information. The class is
 * completely self-contained and has no references to other memory.
 *
 * Copyright (c) 1998 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */

#ifndef _BASE_VERBOSEEXCEPTION_
#define _BASE_VERBOSEEXCEPTION_

#include "base/Exception.h"
#include <string>

class TVerboseException : public TException
{
protected:
  int Code;
  std::string Text;

public:
  TVerboseException(int code) throw ();
  TVerboseException(int code, const char* message) throw ();
  TVerboseException(int code, const std::string& message) throw ();
  ~TVerboseException() throw ();

  int GetCode() const throw ();
  const std::string& GetString() const throw ();
  virtual const char* GetText() const throw ();
  virtual const char* what() const throw ();
};

inline TVerboseException::TVerboseException(int code) throw ()
  : TException(""),
    Code(code)
{
  // Empty constructor body.
}

inline TVerboseException::TVerboseException(int code,
                                            const char* message) throw ()
  : TException(message),
    Code(code),
    Text(message)
{
  // Empty constructor body.
}

inline TVerboseException::TVerboseException(int code,
                                            const std::string& message)
  throw ()
  : TException(""),
    Code(code),
    Text(message)
{
  // Empty constructor body.
}

inline TVerboseException::~TVerboseException() throw ()
{
  // Empty
}

inline int TVerboseException::GetCode() const throw ()
{
  return Code;
}

inline const std::string& TVerboseException::GetString() const throw ()
{
  return Text;
}

inline const char* TVerboseException::GetText() const throw ()
{
  return Text.c_str();
}

inline const char* TVerboseException::what() const throw ()
{
  return Text.c_str();
}

#endif
