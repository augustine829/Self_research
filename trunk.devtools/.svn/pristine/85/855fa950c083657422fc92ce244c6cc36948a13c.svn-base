/*
 *--------------------------------------------------------------------
 *
 * Date.cpp --
 *
 * Klassen TDate
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#include "records/Date.h"
#include <string>
#include <sstream>
#include <iomanip>

TDate::TDate() throw ()
{
  // Empty
}

TDate::TDate(int y, int m, int d) throw ()
  : Year(y), Month(m), Day(d)
{
  // Empty
}

std::string TDate::GetAsString() const throw()
{
  std::ostringstream stream;

  stream << std::setfill('0') << std::setw(4) << Year << "-";
  stream << std::setfill('0') << std::setw(2) << Month << "-";
  stream << std::setfill('0') << std::setw(2) << Day;// << std::ends;
  return std::string(stream.str());
}
