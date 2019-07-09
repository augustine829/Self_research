/*
 *--------------------------------------------------------------------
 *
 * WorkDay.cpp --
 *
 * Klassen TWorkDay
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#include "WorkDay.h"

TWorkDay::TWorkDay() throw() 
  : Travel(0),
    Overtime1(0),
    Overtime2(0),
    Normal(0),
    Leave(0),
    Sick(0),
    Warning(false),
    Vacation(false),
    Half(false)
{
  // Empty
}


TWorkDay::TWorkDay(const std::string& date, int t,
                   int o1, int o2, int nor) throw()
  : Date(date),
    Travel(t),
    Overtime1(o1),
    Overtime2(o2),
    Normal(nor),
    Leave(0),
    Sick(0),
    Warning(false),
    Vacation(false),
    Half(false)
{
  // Empty
}


bool TWorkDay::IsWeekday() const throw ()
{
  if (Day != "lör" && Day != "röd" && Day != "sön") {
    return true;
  }
  return false;
}
