/*
 *--------------------------------------------------------------------
 *
 * Department.h --
 *
 * Klassen TDepartment
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef DEPARTMENT_H
#define DEPARTMENT_H

#include "list/Customer.h"
#include "list/Project.h"
#include "base/VerboseException.h"
#include <vector>

class TDepartment
{
private:
  int Number;
  std::vector<TProject> List;

public:
  TDepartment() throw ();
  int GetNumber() throw ();
  int GetSize() throw ();
  void SetNumber(int number) throw ();
  void SetList(TProject value) throw ();
  TProject& operator[](int index) throw (TVerboseException);
};

inline void TDepartment::SetList(TProject value) throw ()
{
  List.push_back(value);
}

inline int TDepartment::GetNumber() throw ()
{
  return Number;
}

inline int TDepartment::GetSize() throw ()
{
  return List.size();
}

inline void TDepartment::SetNumber(int number) throw ()
{
  Number = number;
}

inline TProject& TDepartment::operator[](int index) throw(TVerboseException)
{
  if(index >= 0 && index < List.size()) {
    return List[index];
  }
  else {
    throw TVerboseException(0, "Bound error in class TDepartment");
  }
}

#endif
