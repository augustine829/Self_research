/*
 *--------------------------------------------------------------------
 *
 * WorkDay.h --
 *
 * Klassen TWorkDay
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef WORKDAY_H
#define WORKDAY_H

#include <string>
#include <iostream>
#include <iomanip>

#include "Constants.h"

class TWorkDay
{
public:
  std::string Date;
  std::string Day;
  int Travel;
  int Overtime1;
  int Overtime2;
  int Normal;
  int Leave;
  int Sick;
  bool Warning;
  bool Vacation;
  bool Half;

  TWorkDay() throw();
  TWorkDay(const std::string& Date, int t,
           int o1, int o2, int nor) throw();
  int GetTotal() const throw();
  int GetFlex(bool inMoney) const throw ();
  void Clear() throw ();
  bool IsWeekday() const throw ();
  bool IsSick() const throw ();
  bool IsSickOk() const throw ();
};

inline int TWorkDay::GetTotal() const throw ()
{
  return (Travel + Overtime1 + Overtime2 + Normal + Leave);
}

inline bool TWorkDay::IsSick() const throw ()
{
  if (Sick > 0) {
    return true;
  }
  return false;
}

inline bool TWorkDay::IsSickOk() const throw ()
{
  if ((Sick + Normal + Leave > WORK_MINUTES_PER_DAY) && IsSick()) {
    return false;
  }
  return true;
}

inline int TWorkDay::GetFlex(bool inMoney) const throw ()
{
  int workMinutes = WORK_MINUTES_PER_DAY;
  if (Half) {
    workMinutes /= 2;
  }
  // Man ska inte få extra flex pga av permission
  int flex = Normal + Leave + Sick - workMinutes;

  // Detta förutsätter att man bara registrarar sjukdom på vardagar
  // annars får man konstig flex
  if (Vacation || (IsSick() && (Normal + Leave == 0))) {
    flex = 0;
  }
  if (!IsWeekday()) {
    flex = Normal + Leave;
  }
  if (!inMoney) {
    // +/-0.5 minuter bli fel?
    flex += static_cast<int>(1.5 * Overtime1);
    flex += 2 * Overtime2;
  }
  return flex;
}

inline void TWorkDay::Clear() throw ()
{
  Travel = 0;
  Overtime1 = 0;
  Overtime2 = 0;
  Normal = 0;
  Leave = 0;
  Sick = 0;
  Warning = false;
  Vacation = false;
  Half = false;
  Day = "";
}
#endif
