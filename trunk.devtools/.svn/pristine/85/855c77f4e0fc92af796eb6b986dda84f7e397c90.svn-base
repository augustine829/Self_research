/*
 *--------------------------------------------------------------------
 *
 * Warning.h --
 *
 * Klassen TWarning
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef WARNING_H
#define WARNING_H

#include "records/Row.h"
#include <string>

class TWarning
{
public:
  std::string Text;
  std::string Date;

  TWarning() throw ();
  TWarning(std::string text, std::string date) throw ();
  TWarning& operator =(TWarning value) throw ();
};


inline TWarning& TWarning::operator= (TWarning value) throw ()
{
  Text = value.Text;
  Date = value.Date;
  return *this;
}

#endif
