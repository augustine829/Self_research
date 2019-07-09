/*
 *--------------------------------------------------------------------
 *
 * Warning.cpp --
 *
 * Klassen TWarning
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */

#include "Warning.h"

TWarning::TWarning() throw ()
{
  // Empty
}

TWarning::TWarning(std::string text, std::string date) throw ()
  : Text(text), Date(date)
{
  // Empty	
}
