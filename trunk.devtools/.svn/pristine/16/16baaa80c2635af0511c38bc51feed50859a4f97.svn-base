/*
 *--------------------------------------------------------------------
 *
 * Row.cpp --
 *
 * Klassen TRow
 *
 * Copyright (c) 2000 Kreatel Communications AB
 * Copyright (c) 2013 Motorola Mobility, Inc. All rights reserved.
 *
 * This program is confidential and proprietary to Motorola Mobility, Inc and
 * may not be copied, reproduced, disclosed to others, published or used, in
 * whole or in part, without the expressed prior written permission of Motorola
 * Mobility, Inc.
 *
 *--------------------------------------------------------------------
 */
#include "Row.h"

TRow::TRow() throw()
  : Date(0, 0, 0)
{
  // Empty
}
	
TRow::TRow(const TDate& date,
           const std::string& day,
           const TTime& from,
           const TTime& to,
           const std::string& timeType,
           int department,
           int project,
           int customer,
           const std::string& activity, 
           const std::string& comment) throw()
  : Date(date),
    Day(day),
    FromTime(from),
    ToTime(to),
    TimeType(timeType),
    Department(department),
    Project(project),
    Customer(customer),
    Activity(activity),
    Comment(comment)
{
  // Empty
}

TRow& TRow::operator =(const TRow& value)
{
  Date = value.Date;
  Day = value.Day;
  FromTime = value.FromTime;	  
  ToTime = value.ToTime;
  TimeType = value.TimeType;
  Department = value.Department;
  Project = value.Project;
  Customer = value.Customer;
  Activity = value.Activity;
  return *this;
}
