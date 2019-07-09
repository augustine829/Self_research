/*
 *--------------------------------------------------------------------
 *
 * List.h --
 *
 * Klassen TList
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef LIST_H
#define LIST_H

#include "base/VerboseException.h"
#include <vector>
#include <string>

template <class T>
class TList
{
private:
  int Number;
  std::vector<T> List;

public:
  TList() throw();
  int GetNumber() throw ();
  int GetSize() throw ();
  void SetNumber(int number) throw ();
  void SetList(T value) throw ();
  T& operator[](int index) throw(TVerboseException);
};

template <class T>
inline void TList<T>::SetList(T value) throw ()
{
  List.push_back(value);
}

template <class T>
inline int TList<T>::GetNumber() throw ()
{
  return Number;
}

template <class T>
inline int TList<T>::GetSize() throw ()
{
  return List.size();
}

template <class T>
inline void TList<T>::SetNumber(int number) throw ()
{
  Number = number;
}

template <class T>
inline T& TList<T>::operator[](int index) throw(TVerboseException)
{
  if(index >= 0 && index < List.size()) {
    return List[index];
  }
  else {
    throw TVerboseException(0, "Bound error in class TList");
  }
} 

#endif
