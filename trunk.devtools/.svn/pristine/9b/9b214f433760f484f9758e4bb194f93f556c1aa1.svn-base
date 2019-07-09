/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *---------------------------------------------------------------------------
 *
 * test/TMethodRecorder.h
 *
 * Helper class to record 
 *
 * Copyright (c) 2004 Kreatel Communications AB. All Rights Reserved.
 *
 *---------------------------------------------------------------------------
 */

#ifndef TEST_TMETHODRECORDER_H
#define TEST_TMETHODRECORDER_H

#include <list>
#include <string>


class TMethodRecorder
{
protected:
  std::list<std::string> MethodSequence;

public:
  void Push(const char* format ...); 
  void Push(const std::string& name); 
  const std::string& GetFront() const;
  std::string Pop();
  bool PopUntil(const char* name);
  bool IsRecorded(const std::string& name) const;
  bool IsEmpty() const;
  void Clear();

  // Useful for debugging:
  void Print() const;
};


inline bool TMethodRecorder::IsEmpty() const
{
  return MethodSequence.empty();
}

inline void TMethodRecorder::Clear()
{
  MethodSequence.clear();
}

#endif // TEST_TMETHODRECORDER_H
