/*
 *--------------------------------------------------------------------
 *
 * Record.cpp --
 *
 * Klassen TRecord
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#include "Record.h"
#include <iostream>
#include <iomanip>

TRecord::TRecord() throw ()
{
  // Empty
}

bool TRecord::GetInMoney() const throw ()
{
  if (InMoney == "ja" || InMoney == "JA") {
    return true;
  }
  return false;
}

TRecord& TRecord::operator=(const TRecord& r) throw ()
{
  Name = r.Name;
  InMoney = r.InMoney;
  InFlex = r.InFlex;
  InKomp = r.InKomp;
  OutKomp = r.OutKomp;
  InOvertime1 = r.InOvertime1;
  InOvertime2 = r.InOvertime2;
  Year = r.Year;
  Month = r.Month;
  Rows = r.GetRows();
  return *this;
}
