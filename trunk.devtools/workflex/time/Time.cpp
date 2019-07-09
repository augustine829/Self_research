/*
 *--------------------------------------------------------------------
 *
 * Time.cpp --
 *
 * Klassen TTime
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#include "Time.h"
#include <string>
#include <sstream>
#include <iomanip>
#include <iostream>

TTime::TTime() throw()
  : Hours(0), Minutes(0), Negative(false) 
{
  // Empty
}

TTime::TTime(int h, int min, bool negative) throw()
  : Hours(h), Minutes(min), Negative(negative)
{
  // Empty
}

std::string TTime::GetAsString() const throw()
{
  std::ostringstream stream;

  if (Negative) {
    stream << '-';
  }
  stream << std::setfill('0') << std::setw(2) << Hours << ":";
  stream << std::setfill('0') << std::setw(2) << Minutes;// << std::ends;
  return std::string(stream.str());
}

TTime& TTime::operator= (const TTime& value) throw ()
{
  Hours = value.GetHours();
  Minutes = value.GetMinutes();
  Negative = value.IsNegative();
  return *this;
}
