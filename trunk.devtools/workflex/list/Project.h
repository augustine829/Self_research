/*
 *--------------------------------------------------------------------
 *
 * Project.h --
 *
 * Klassen TProject
 *
 * Copyright (c) 2000 Kreatel Communications AB
 * Copyright (c) 2013 Motorola Mobility, Inc. All rights reserved.
 *
 * This program is confidential and proprietary to Motorola Mobility, Inc and
 * may not be copied, reproduced, disclosed to others, published or used, in
 * whole or in part, without the expressed prior written permission of Motorola
 * Mobility, Inc.
 *
 *--------------------------------------------------------------------
 */
#ifndef PROJECT_H
#define PROJECT_H

#include "list/Customer.h"
#include "base/VerboseException.h"
#include <vector>

class TProject
{
private:
  int Number;
  std::vector<TCustomer> List;

public:
  TProject() throw ();
  int GetNumber() throw ();
  int GetSize() throw ();
  void SetNumber(int number) throw ();
  void SetList(TCustomer value) throw ();
  TCustomer& operator[](int index) throw (TVerboseException);
};


inline void TProject::SetList(TCustomer value) throw ()
{
  List.push_back(value);
}


inline int TProject::GetNumber() throw ()
{
  return Number;
}


inline int TProject::GetSize() throw ()
{
  return List.size();
}


inline void TProject::SetNumber(int number) throw ()
{
  Number = number;
}


inline TCustomer& TProject::operator[](int index) throw(TVerboseException)
{
  if (index >= 0 && (size_t) index < List.size()) {
    return List[index];
  }
  else {
    throw TVerboseException(0, "Bound error in class TProject");
  }
}

#endif
