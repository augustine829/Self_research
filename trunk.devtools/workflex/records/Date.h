/*
 *--------------------------------------------------------------------
 *
 * Date.h --
 *
 * Klassen TDate
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef DATE_H
#define DATE_H

#include <string>

class TDate
{
private:
  int Year;
  int Month;
  int Day;	

public:
  TDate() throw();
  TDate(int y, int m, int d) throw();
  std::string GetAsString() const throw();
  int GetYear() const throw();
  int GetMonth() const throw();
  int GetDay() const throw();
  bool operator ==(const TDate& other) const throw ();
  bool operator !=(const TDate& other) const throw ();
};

inline int TDate::GetYear() const throw()
{
  return Year;
}

inline int TDate::GetMonth() const throw()
{
  return Month;
}

inline int TDate::GetDay() const throw()
{
  return Day;
}

inline bool TDate::operator ==(const TDate& other) const throw ()
{
  return (Year == other.Year && Month == other.Month && Day == other.Day);
}

inline bool TDate::operator !=(const TDate& other) const throw ()
{
  return (Year != other.Year || Month != other.Month || Day != other.Day);
}
#endif

