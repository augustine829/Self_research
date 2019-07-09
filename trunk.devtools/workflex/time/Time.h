/*
 *--------------------------------------------------------------------
 *
 * Time.h --
 *
 * Klassen TTime
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef TIME_H
#define TIME_H

#include <string>

class TTime
{
private:
  int Hours;
  int Minutes;
  bool Negative;

public:
  TTime() throw();
  TTime(int h, int min, bool negative) throw();
  std::string GetAsString() const throw();
  double GetAsDouble() const throw();
  int GetAsMinutes() const throw();
  int GetHours() const throw();
  int GetMinutes() const throw();
  bool IsNegative() const throw();
  TTime& operator= (const TTime& value) throw ();
  bool operator< (const TTime& value) const throw ();
  bool operator> (const TTime& value) const throw ();
  bool operator== (const TTime& value) const throw ();
  bool operator<= (const TTime& value) const throw ();
  bool operator>= (const TTime& value) const throw ();
};

inline int TTime::GetHours() const throw()
{
  return Hours;
}

inline int TTime::GetMinutes() const throw()
{
  return Minutes;
}

inline double TTime::GetAsDouble() const throw()
{
  return static_cast<double>(GetAsMinutes()) / 60;
}

inline bool TTime::IsNegative() const throw()
{
  return Negative;
}

inline int TTime::GetAsMinutes() const throw()
{
  return (Negative ? -1 : 1 ) * (Hours * 60 + Minutes);
}

inline bool TTime::operator< (const TTime& value) const throw ()
{
  return (GetAsString() < value.GetAsString());
}

inline bool TTime::operator> (const TTime& value) const throw ()
{
  return (GetAsString() > value.GetAsString());
}

inline bool TTime::operator== (const TTime& value) const throw ()
{
  return (GetAsString() == value.GetAsString());
}

inline bool TTime::operator<= (const TTime& value) const throw ()
{
  return (GetAsString() <= value.GetAsString());
}

inline bool TTime::operator>= (const TTime& value) const throw ()
{
  return (GetAsString() >= value.GetAsString());
}

#endif
