/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *---------------------------------------------------------------------------
 *
 * test/TMethodRecorder.cpp
 *
 * Helper class to record 
 *
 * Copyright (c) 2004 Kreatel Communications AB. All Rights Reserved.
 *
 *---------------------------------------------------------------------------
 */

#include "TMethodRecorder.h"
#include "TTestException.h"

#include <stdio.h>
#include <stdarg.h>


void TMethodRecorder::Push(const char* format ...)
{
  va_list ap;
  va_start(ap, format);

  enum { STACK_BUFFER_SIZE = 256 };

  char stackBuf[STACK_BUFFER_SIZE];
  char* heapBuf = NULL;
  char* buffer = &stackBuf[0];
  int capacity = STACK_BUFFER_SIZE;

  while (true) {
    int result = ::vsnprintf(buffer, capacity, format, ap);
    if (result > capacity) {
      // The output didn't fit in the stack buffer. Allocate a buffer
      // large enough on the heap and redo the complete process.
      heapBuf = new char[result + 1];
      buffer = heapBuf;
      capacity = result + 1;
    }
    else {
      break;
    }
  }
  MethodSequence.push_back(buffer);

  delete[] heapBuf;
  va_end(ap);
}

void TMethodRecorder::Push(const std::string& name)
{
  MethodSequence.push_back(name);
}

const std::string& TMethodRecorder::GetFront() const
{
  return MethodSequence.front();
}

std::string TMethodRecorder::Pop()
{
  if (MethodSequence.empty()) {
    //throw TTestException("Method recorder is empty", __LINE__, __FILE__);
    return "";
  }
  std::string name = MethodSequence.front();
  MethodSequence.pop_front();
  return name;
}

bool TMethodRecorder::PopUntil(const char* name)
{
  while (!MethodSequence.empty()) {
    if (MethodSequence.front() != name) {
      MethodSequence.pop_front();
    }
    else {
      MethodSequence.pop_front();
      return true;
    }
  }
  return false;  // A matching name was not found.
}

bool TMethodRecorder::IsRecorded(const std::string& name) const
{
  std::list<std::string>::const_iterator i;
  for (i = MethodSequence.begin(); i != MethodSequence.end(); ++i) {
    if (name == *i) {
      return true;
    }
  }
  return false;
}

void TMethodRecorder::Print() const
{
  std::list<std::string>::const_iterator i;
  for (i = MethodSequence.begin(); i != MethodSequence.end(); ++i) {
    ::printf("  %s\n", (*i).c_str());
  }
}
