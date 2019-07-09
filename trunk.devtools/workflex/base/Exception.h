/*
 *--------------------------------------------------------------------
 *
 * base/Exception.h
 *
 * The base class for Kreatel exceptions.
 *
 * Copyright (c) 1996-2000 Kreatel Communications AB. All Rights Reserved.
 *
 *--------------------------------------------------------------------
 */

#ifndef BASE_EXCEPTION_H
#define BASE_EXCEPTION_H

#include <exception>

// ----------------------------------------------------------------------------
// TException

class TException : public std::exception
{
private:
  const char* Message;

public:
  TException(const char* message) throw ();
  virtual ~TException() throw ();

  virtual const char* GetText() const throw ();
  virtual const char* what() const throw ();
};

// ----------------------------------------------------------------------------
// Inlined methods


inline TException::TException(const char* message) throw ()
  : Message(message)
{
  // empty
}

inline TException::~TException() throw ()
{
  // empty
}

inline const char* TException::GetText() const throw ()
{
  return Message;
}

inline const char* TException::what() const throw ()
{
  return Message;
}

#endif
