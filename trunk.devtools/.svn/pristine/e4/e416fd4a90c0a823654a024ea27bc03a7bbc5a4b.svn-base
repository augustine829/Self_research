/*
 *--------------------------------------------------------------------
 *
 * Row.h --
 *
 * Klassen TRow
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef ROW_H
#define ROW_H

#include "time/Time.h"
#include "records/Date.h"
#include <string>

class TRow
{
public:
  TDate Date;
  std::string Day;
  TTime FromTime;	  
  TTime ToTime;
  std::string TimeType;
  int Department;
  int Project;
  int Customer;
  std::string Activity;
  std::string Comment;

  TRow() throw();
  TRow(const TDate& date, const std::string& day, const TTime& from,
       const TTime& to, const std::string& timeType, int department,
       int project, int customer, const std::string& Activity,
       const std::string& comment) throw();
  TRow& operator =(const TRow& value);	
};
#endif

