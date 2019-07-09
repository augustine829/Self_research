/*
 *--------------------------------------------------------------------
 *
 * Print.h --
 *
 * Klassen TPrint
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

#ifndef PRINT_H
#define PRINT_H

#include "records/Record.h"
#include "time/Time.h"
#include "records/Row.h"
#include "list/Project.h"
//#include "list/Department.h"
#include "list/Customer.h"
#include "time/WorkDay.h"
#include "warning/Warning.h"
#include <string>
#include <fstream>


class TPrint
{
private:
  //typedef std::vector<TDepartment> TTree;

  TRecord Record;
  //TTree Tree;
  std::vector<TWorkDay> WorkDayVector;
  std::vector<int> rowIndex;
  std::vector<TWarning> Warnings;
  int AccFlex;
  int Flex;
  int AccKomp;
  int AccOvertime1;
  int AccOvertime2;
  int Total;
  int Vacation;
  int Weekdays;
  int Travel;
  int Sick;
  int Leave;
  int Normal;
  std::ostream& Stream;

  void Calculate() throw();
  std::string AsString(int min) throw();
  std::string AsFractionalString(int min) throw();
  double AsDouble(int min) throw();
  void AddMinutes(TWorkDay& day, size_t i) throw();
  void SortByDepartment() throw();
  int FindDepartmentNumber(int number) throw ();
  int FindProjectNumber(int number, int d) throw ();
  int FindCustomerNumber(int number, int d, int p) throw ();
  //void PrintTree() throw();
  void PrintTableRow(const std::string& type, int time,
                     bool isTime = true) throw();
  void PrintTableRow(const std::string& type, TTime time) throw();
  void PrintTableRow(const std::string& type, double d) throw();
  void PrintTableRow(const std::string& str1, std::string str2) throw();
  void PrintTableRow(const std::string& date,
                     int total, int flex, 
                     int normal, int o1,
                     int o2, int travel) throw();
  void PrintLine(char fillChar, int width) throw();
  void PrintTableHeader(const std::string& text) throw();
  void PrintWarning(bool isWarning) throw();
  void PrintProjectRow(const std::string& activity,
                       int normal, int overtime1,
                       int overtime2, int travel) throw ();

public:
  //TPrint() throw();
  TPrint(TRecord r, std::ostream& stream) throw();
  ~TPrint() throw();
  void PrintDaySummary() throw();
  void PrintSummary() throw();
  void PrintProjectDaySummary() throw ();
};

#endif
