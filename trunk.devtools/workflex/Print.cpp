/*
 *--------------------------------------------------------------------
 *
 * Print.cpp --
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
#include "Print.h"
#include "records/Row.h"

#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

/*TPrint::TPrint() throw ()
  : Vacation(0), Total(0), Flex(0), Weekdays(0), Travel(0),
    Sick(0), Leave(0), Normal(0), Stream(0)
{
  AccFlex = Record.InFlex.GetAsMinutes() - Record.OutKomp.GetAsMinutes();
  AccKomp = Record.InKomp.GetAsMinutes() + Record.OutKomp.GetAsMinutes();
  AccOvertime1 = Record.InOvertime1.GetAsMinutes();
  AccOvertime2 = Record.InOvertime2.GetAsMinutes();
}*/

TPrint::TPrint(TRecord r, std::ostream& stream) throw ()
  : Flex(0),
    Total(0),
    Vacation(0),
    Weekdays(0),
    Travel(0),
    Sick(0),
    Leave(0),
    Normal(0),
    Stream(stream)
{
  Record = r;
  AccFlex = Record.InFlex.GetAsMinutes() - Record.OutKomp.GetAsMinutes();
  AccKomp = Record.InKomp.GetAsMinutes() + Record.OutKomp.GetAsMinutes();
  AccOvertime1 = Record.InOvertime1.GetAsMinutes();
  AccOvertime2 = Record.InOvertime2.GetAsMinutes();
  Calculate();
  //SortByDepartment();
}

TPrint::~TPrint() throw ()
{
  // empty
}

void TPrint::PrintDaySummary() throw()
{
  Stream //<< std::endl << std::endl
         << " Datum"
         << std::setfill(' ') << std::setw(5);
  Stream << " " << std::setfill(' ') << std::setw(10) << "Total";
  Stream << std::setfill(' ') << std::setw(10) << "Flex";
  Stream << std::setfill(' ') << std::setw(10) << "Normal";
  Stream << std::setfill(' ') << std::setw(10) << "�vertid1";
  Stream << std::setfill(' ') << std::setw(10) << "�vertid2";
  Stream << std::setfill(' ') << std::setw(9) << "Restid" << std::endl;
  PrintLine('-', 70);

  for (size_t i = 0; i < WorkDayVector.size(); i++) {
    int total = WorkDayVector[i].GetTotal();
    bool warning = false;

    if (!WorkDayVector[i].IsSickOk()) {
      warning = true;
      Warnings.push_back(TWarning("Om du �r sjuk, kan du knappast registrera "
                                  "fler �n totalt 7,5 timmar.",
                                  WorkDayVector[i].Date));
    }
    else if (total > 10 * 60 && !WorkDayVector[i].Vacation &&
             WorkDayVector[i].IsWeekday() && !WorkDayVector[i].IsSick()) {
      warning = true;
      Warnings.push_back(TWarning("Du har jobbat l�nge!",
                                  WorkDayVector[i].Date));
    }
    else if (total < 6 * 60 && !WorkDayVector[i].Vacation &&
             !WorkDayVector[i].Half &&
             WorkDayVector[i].IsWeekday() &&
             !WorkDayVector[i].IsSick()) {
      warning = true;
      Warnings.push_back(TWarning("Du har jobbat lite!",
                                  WorkDayVector[i].Date));
    }
    PrintWarning(warning);
    PrintTableRow(WorkDayVector[i].Date, total + WorkDayVector[i].Sick,
                  WorkDayVector[i].GetFlex(true),
                  WorkDayVector[i].Normal + WorkDayVector[i].Leave,
                  WorkDayVector[i].Overtime1, WorkDayVector[i].Overtime2,
                  WorkDayVector[i].Travel);
  }
  PrintLine('-', 70);

}

void TPrint::PrintSummary() throw()
{
  bool flex = false;
  bool komp = false;
  bool overtime = false;
  bool total = false;
  // Print work hours sorted by dept-project-customer
  //PrintTree();

  // Print work-hours-table
  PrintTableHeader("Arbetsinformation");
  PrintLine('-', 70);
  PrintWarning(false);
  PrintTableRow("Antal arbetsdagar denna m�nad:", Weekdays * 60, false);
  PrintWarning(false);
  PrintTableRow("Antal arbetstimmar denna m�nad:",
                Weekdays * WORK_MINUTES_PER_DAY);
  PrintLine('-', 70);

  PrintTableHeader("M�nadsrapport");
  PrintLine('-', 70);
  PrintWarning(false);
  PrintTableRow("Normaltid denna m�nad:", Normal - Leave);
  PrintWarning(false);
  PrintTableRow("Permissionstid denna m�nad:", Leave);
  PrintWarning(false);
  PrintTableRow("�vertid denna m�nad(�1 + �2):",
                AccOvertime1 - Record.InOvertime1.GetAsMinutes() +
                AccOvertime2 - Record.InOvertime2.GetAsMinutes());
  PrintWarning(false);
  PrintTableRow("Restid denna m�nad:", Travel);
  PrintWarning(false);
  PrintTableRow("Totalt antal arbetade timmar denna m�nad:", Total);
  Stream << std::endl;
  PrintWarning(false);
  PrintTableRow("Semesterdagar denna m�nad:", static_cast<double>(Vacation));
  PrintWarning(false);
  PrintTableRow("Sjuktimmar denna m�nad:", Sick);
  PrintWarning(false);
  PrintTableRow("Sjukdagar denna m�nad:",
                static_cast<double>(Sick) / WORK_MINUTES_PER_DAY);

  PrintLine('-', 70);

  // Print "flex" and "komp" table
  PrintTableHeader("Flex- och komptid");
  PrintLine('-', 70);
  PrintWarning(false);
  PrintTableRow("Ing�ende komptid:", Record.InKomp);
  PrintWarning(false);
  PrintTableRow("Ing�ende flextid:", Record.InFlex);
  PrintWarning(false);
  PrintTableRow("Flextid denna m�nad:", Flex);
  PrintWarning(false);
  PrintTableRow("Komptid denna m�nad:", Record.OutKomp);
  if (AccFlex < -10 * 60 || AccFlex > 100 * 60) {
    flex = true;
    Warnings.push_back(TWarning("Flexsaldo m�ste ligga mellan "
                                "-10:00 och 100:00 vid varje m�nadsskifte.",
                                "Flexsaldo:"));
  }
  PrintWarning(flex);
  PrintTableRow("Flexsaldo:", AccFlex);
  if (AccKomp > 100 * 60) {
    komp = true;
    Warnings.push_back(TWarning("Kompsaldo f�r inte �verstiga 100:00 "
                                "timmar per �r.", "Kompsaldo:"));
  }
  PrintWarning(komp);
  PrintTableRow("Kompsaldo:", AccKomp);
  PrintLine('-', 70);

  // Print overtime table
  PrintTableHeader("�vertid");
  PrintLine('-', 70);
  PrintWarning(false);
  PrintTableRow("Ing�ende �vertid1:", Record.InOvertime1);
  PrintWarning(false);
  PrintTableRow("Ing�ende �vertid2:", Record.InOvertime2);
  PrintWarning(false);
  PrintTableRow("�vertid1 denna m�nad:",
                AccOvertime1 - Record.InOvertime1.GetAsMinutes());
  PrintWarning(false);
  PrintTableRow("�vertid2 denna m�nad:",
                AccOvertime2 - Record.InOvertime2.GetAsMinutes());
  if (AccOvertime1 - Record.InOvertime1.GetAsMinutes() +
      AccOvertime2 - Record.InOvertime2.GetAsMinutes() > 50 * 60) {
    overtime = true;
    Warnings.push_back(TWarning("�vertiden denna m�nad f�r inte �verstiga "
                                "50:00 timmar.", "�vertid:"));
  }
  PrintWarning(overtime);
  PrintTableRow("Total �vertid denna m�nad:",
                AccOvertime1 - Record.InOvertime1.GetAsMinutes() +
                AccOvertime2 - Record.InOvertime2.GetAsMinutes());
  PrintWarning(false);
  PrintTableRow("Saldo f�r �vertid1:", AccOvertime1);
  PrintWarning(false);
  PrintTableRow("Saldo f�r �vertid2:", AccOvertime2);
  if (AccOvertime1 + AccOvertime2 + AccKomp > 300 * 60) {
    total = true;
    Warnings.push_back(TWarning("�vertid + komptid f�r inte �verstiga 300:00 "
                                "timmar per �r.", "�vertid:"));
  }
  PrintWarning(total);
  PrintTableRow("Saldo f�r total �vertid + total komptid:",
                AccOvertime1 + AccOvertime2 + AccKomp);
  PrintLine('-', 70);

  // Print payment table
  PrintTableHeader("Utbetalning");
  PrintLine('-', 70);
  PrintWarning(false);
  PrintTableRow("Restid:", Travel);
  PrintWarning(false);
  PrintTableRow("Komptid denna m�nad:", Record.OutKomp);
  if (Record.GetInMoney()) {
    PrintWarning(false);
    PrintTableRow("�vertid1 denna m�nad:",
                  AccOvertime1 - Record.InOvertime1.GetAsMinutes());
    PrintWarning(false);
    PrintTableRow("�vertid2 denna m�nad:",
                  AccOvertime2 - Record.InOvertime2.GetAsMinutes());
  }
  else {
    PrintWarning(false);
    PrintTableRow("�vertid1 denna m�nad:", 0);
    PrintWarning(false);
    PrintTableRow("�vertid2 denna m�nad:", 0);
  }
  PrintLine('-', 70);

  if (Warnings.size() > 0) {
    // Print warning table
    PrintTableHeader("Varningar");
    PrintLine('-', 70);
    for (size_t i = 0; i < Warnings.size(); i++) {
      PrintTableRow(Warnings[i].Date, Warnings[i].Text);
    }
    PrintLine('-', 70);
  }

  // Print signature table
  //PrintTableHeader("Attesteras");
  //PrintLine('-', 70);
  //Stream << std::endl << std::endl << std::endl;
  //PrintLine('_', 50);
  //Stream << "Namnteckning" << std::endl;
}

void TPrint::Calculate() throw()
{
  std::vector<TRow> rows = Record.GetRows();
  TWorkDay day;

  if (rows.size() >= 1) {
    day.Date = rows[0].Date.GetAsString();
    day.Day = rows[0].Day;

    for (size_t i = 0; i < rows.size(); i++) {
      if (day.Date == rows[i].Date.GetAsString()) {
        AddMinutes(day, i);
      }
      else {
        WorkDayVector.push_back(day);
        Travel += day.Travel;
        if (day.IsWeekday()) {
          Weekdays++;
        }
        Flex += day.GetFlex(Record.GetInMoney());
        Normal += day.Leave + day.Normal;
        Total += day.GetTotal();
        Sick += day.Sick;
        AccOvertime1 += day.Overtime1;
        AccOvertime2 += day.Overtime2;
        day.Clear();
        day.Date = rows[i].Date.GetAsString();
        day.Day = rows[i].Day;
        AddMinutes(day, i);
      }
    }
    WorkDayVector.push_back(day);
    Travel += day.Travel;
    if (day.IsWeekday()) {
      Weekdays++;
    }
    Flex += day.GetFlex(Record.GetInMoney());
    // Leave r�knas som normal
    Total += day.GetTotal();
    Normal += day.Leave + day.Normal;
    AccFlex += Flex;
    Sick += day.Sick;
    AccOvertime1 += day.Overtime1;
    AccOvertime2 += day.Overtime2;
  }
}


std::string TPrint::AsString(int min) throw()
{
  std::ostringstream stream;

  if (min < 0) {
    stream << "-";
  }
  stream << std::setfill('0') << std::setw(2) << abs(min / 60) << ":";
  stream << std::setfill('0') << std::setw(2) << abs(min % 60);// << std::ends;
  return std::string(stream.str());
}

std::string TPrint::AsFractionalString(int min) throw()
{
  std::ostringstream stream;
  int hours = min / 60;
  int fraction = (min % 60) * 100 / 60;

  if (fraction != 0) {
    stream << std::setfill('0')
           << std::setw(1) << hours << "."
           << std::setw(2) << fraction;
  }
  else{
    stream << std::setfill('0') << std::setw(1) << hours;
  }

  return std::string(stream.str());
}

double TPrint::AsDouble(int min) throw()
{
  return static_cast<double>(min) / 60;
}


void TPrint::AddMinutes(TWorkDay& day, size_t i) throw()
{
  std::vector<TRow> rows = Record.GetRows();

  if (i < rows.size()) {
    if (rows[i].TimeType == "n" || rows[i].TimeType == "N") {
      day.Normal += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "h" || rows[i].TimeType == "H") {
      day.Normal += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
      day.Half = true;
    }
    else if (rows[i].TimeType == "r" || rows[i].TimeType == "R") {
      if (day.IsWeekday() &&
          !((rows[i].FromTime < TTime(8, 30, false)
             && rows[i].ToTime <= TTime(8, 0, false)) ||
            (rows[i].FromTime >= TTime(17, 00, false)
             && rows[i].ToTime > TTime(17, 0, false)))) {
        day.Warning = true;
        Warnings.push_back(TWarning("Restid r�knas endast utanf�r intervallet "
                                    "helgfria m�n-fre 8:30-17:00.",
                                    rows[i].Date.GetAsString()));
        rowIndex.push_back(i);
      }
      day.Travel += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "�1" || rows[i].TimeType == "�1") {
      if (day.IsWeekday()) {
        if (day.Normal < WORK_MINUTES_PER_DAY) {
          day.Warning = true;
          Warnings.push_back(TWarning("Du m�ste ha jobbat mer �n 7,5 timmar "
                                      "f�r att f� ut �vertid1 denna "
                                      "dag.", rows[i].Date.GetAsString()));
          rowIndex.push_back(i);
        }
        else if (rows[i].FromTime < TTime(6, 0, false)
                 || rows[i].ToTime > TTime(20, 0, false)) {
          day.Warning = true;
          Warnings.push_back(TWarning("F�re 06:00 och efter 20:00 �r all "
                                      "�vertid av typ 2.",
                                      rows[i].Date.GetAsString()));
          rowIndex.push_back(i);
        }
      }
      else {
        day.Warning = true;
        Warnings.push_back(TWarning("P� r�d, l�r och s�n �r all �vertid av "
                                    "typ 2.", rows[i].Date.GetAsString()));
        rowIndex.push_back(i);
      }
      day.Overtime1 += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "�2" || rows[i].TimeType == "�2") {
      if (day.IsWeekday()) {
        if (day.Normal < WORK_MINUTES_PER_DAY) {
          day.Warning = true;
          Warnings.push_back(TWarning("Du m�ste ha jobbat mer �n 7,5 timmar "
                                      "f�r att f� ut �vertid2 denna "
                                      "dag.", rows[i].Date.GetAsString()));
          rowIndex.push_back(i);
        }
        else if (!((rows[i].FromTime < TTime(6, 0, false)
                    && rows[i].ToTime <= TTime(6, 0, false)) ||
                   ((rows[i].FromTime >= TTime(20, 0, false)
                     && rows[i].ToTime > TTime(20, 0, false))))) {
          day.Warning = true;
          Warnings.push_back(TWarning("�vertid2 f�r enbart tas ut f�re 06:00 "
                                      "eller efter 20:00 p� vardagar.",
                                      rows[i].Date.GetAsString()));
          rowIndex.push_back(i);
        }
      }
      day.Overtime2 += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "s" || rows[i].TimeType == "S") {
      day.Vacation = true;
      Vacation++;
    }
    else if (rows[i].TimeType == "sj" || rows[i].TimeType == "SJ") {
      day.Sick = rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
      day.Warning = true;
      Warnings.push_back(TWarning("Sjukdom", rows[i].Date.GetAsString()));
      rowIndex.push_back(i);

    }
    else if (rows[i].TimeType == "p" || rows[i].TimeType == "P") {
      day.Leave += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
      Leave += rows[i].ToTime.GetAsMinutes() - rows[i].FromTime.GetAsMinutes();
    }
    else {
      // Error
    }
  }
}

void TPrint::PrintProjectRow(const std::string& activity,
                             int normal, int overtime1, int overtime2,
                             int travel) throw ()
{
  Stream << " " << std::setfill(' ') << std::left
         << std::setw(20) << activity << " " << std::right;
  Stream << std::setfill(' ') << std::setw(9)
         << AsFractionalString(normal) << " ";
  Stream << std::setfill(' ') << std::setw(9)
         << AsFractionalString(overtime1) << " ";
  Stream << std::setfill(' ') << std::setw(9)
         << AsFractionalString(overtime2) << " ";
  Stream << std::setfill(' ') << std::setw(9)
         << AsFractionalString(travel) << std::endl;
  Stream << std::left;
}

struct TTimes { int t1; int t2; int t3; int t4; };

void TPrint::PrintProjectDaySummary() throw ()
{
  TDate d;
  std::map<std::string, TTimes> activities;
  std::map<std::string, TTimes>::iterator activity = activities.end();

  std::vector<TRow> rows = Record.GetRows();
  if (rows.size() == 0 || rows[0].Activity == "") {
    return;
  }

  Stream << "\n\n Aktivitet            "
         << std::setfill(' ') << std::setw(9)  << "Normal" << " ";
  Stream << std::setfill(' ') << std::setw(9)  << "�vertid1" << " ";
  Stream << std::setfill(' ') << std::setw(9)  << "�vertid2" << " ";
  Stream << std::setfill(' ') << std::setw(9)  << "Restid" << std::endl;
  Stream << std::setfill('-') << std::setw(70) << "-";

  for (size_t i = 0; i < rows.size(); i++) {
    if (d != rows[i].Date) {
      for (activity = activities.begin();
           activity != activities.end(); ++activity) {
        PrintProjectRow(activity->first, activity->second.t1,
                        activity->second.t2, activity->second.t3,
                        activity->second.t4);
      }
      activities.clear();
      activity = activities.end();
      d = rows[i].Date;
      if (rows[i].Day == "m�n") {
        Stream << "\n------\n";
      }
      Stream << "\n" << d.GetAsString() << " " << rows[i].Day << "\n";
    }
    activity = activities.find(rows[i].Activity);
    if (activity == activities.end()) {
      TTimes t;
      t.t1 = 0;
      t.t2 = 0;
      t.t3 = 0;
      t.t4 = 0;
      activities.insert(std::map<std::string,
                        TTimes>::value_type(rows[i].Activity, t));
      activity = activities.find(rows[i].Activity);
    }
    if (rows[i].TimeType == "n" || rows[i].TimeType == "N" ||
        rows[i].TimeType == "p" || rows[i].TimeType == "P" ||
        rows[i].TimeType == "h" || rows[i].TimeType == "H") {
      activity->second.t1 += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "r" || rows[i].TimeType == "R") {
      activity->second.t4 += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "�1" || rows[i].TimeType == "�1") {
      activity->second.t2 += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "�2" || rows[i].TimeType == "�2") {
      activity->second.t3 += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
  }
  for (activity = activities.begin();
       activity != activities.end(); ++activity) {
    PrintProjectRow(activity->first, activity->second.t1,
                    activity->second.t2, activity->second.t3,
                    activity->second.t4);
  }
  Stream << "\n";
}


/*void TPrint::SortByDepartment() throw()
{
  std::vector<TRow> rows = Record.GetRows();
	

  for (int i = 0; i < rows.size(); i++) {	
    int normal = 0;
    int travel = 0;
    int overtime1 = 0;
    int overtime2 = 0;
    int vaction = 0;
    int department = FindDepartmentNumber(rows[i].Department);
    int project = FindProjectNumber(rows[i].Project, department);
    int customer = FindCustomerNumber(rows[i].Customer, department, project);
		
    if (rows[i].TimeType == "n" || rows[i].TimeType == "N" ||
        rows[i].TimeType == "p" || rows[i].TimeType == "P") {
      normal += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "r" || rows[i].TimeType == "R") {
      travel += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
        }
    else if (rows[i].TimeType == "�1" || rows[i].TimeType == "�1") {
      overtime1 += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }
    else if (rows[i].TimeType == "�2" || rows[i].TimeType == "�2") {
      overtime2 += rows[i].ToTime.GetAsMinutes()
        - rows[i].FromTime.GetAsMinutes();
    }

    TCustomer cust(rows[i].Customer, travel,
                   overtime1, overtime2, normal);
    TProject proj;
    TDepartment dept;
    proj.SetNumber(rows[i].Project);
    proj.SetList(cust);
    dept.SetNumber(rows[i].Department);
    dept.SetList(proj);	

    if (department == -1) { 
      Tree.push_back(dept);	
      return;
    }
    else {
      if (project == -1) {
        // Create new Project and Customer
        Tree[department].SetList(proj);
      }
      else {
        if (customer == -1) {
          // Add Customer
          Tree[department][project].SetList(cust);
        }
        else {
          // Add hours
          Tree[department][project][customer].AddHours(cust);
        }
      }
    }
  }
}

int TPrint::FindDepartmentNumber(int number) throw()
{
  for (int i = 0; i < Tree.size(); i++) {
    if (number == Tree[i].GetNumber()) {
      return i;
    }
  }
  return -1;
}

int TPrint::FindProjectNumber(int number, int d) throw()
{
  if (d == -1) {
    return -1;
  }
  for (int i = 0; i < Tree[d].GetSize(); i++) {
    if (number == Tree[d][i].GetNumber()) {
      return i;
    }
  }
  return -1;
}

int TPrint::FindCustomerNumber(int number, int d, int p) throw()
{
  if (d == -1 || p == -1) {
    return -1;
  }
  for (int i = 0; i < Tree[d][p].GetSize(); i++) {
    if (number == Tree[d][p][i].Number) {
      return i;
    }
  }
  return -1;
}*/

/*void TPrint::PrintTree() throw()
{
  Stream << std::endl<< " Enhet-Projekt-Kund    " << " "
         << std::setfill(' ') << std::setw(9)  << "Normal" << " ";
  Stream << std::setfill(' ') << std::setw(9)  << "�vertid1" << " ";
  Stream << std::setfill(' ') << std::setw(9)  << "�vertid2" << " ";
  Stream << std::setfill(' ') << std::setw(9)  << "Restid" << std::endl;
  Stream << std::setfill('-') << std::setw(70) << "-" << std::endl;
  for (int i = 0; i < Tree.size(); i++) {		
    for (int j = 0; j < Tree[i].GetSize(); j++) {			
      for (int k = 0; k < Tree[i][j].GetSize(); k++) {
        PrintWarning(false);
        Stream << std::setfill('0') << std::setw(5)
               << Tree[i].GetNumber() << "-";
        Stream << std::setfill('0') << std::setw(5)
               << Tree[i][j].GetNumber() << "-";
        Stream << std::setfill('0') << std::setw(10)
               << Tree[i][j][k].Number << " ";
        Stream << std::setfill(' ') << std::setw(9)
               << AsString(Tree[i][j][k].Normal) << " ";
        Stream << std::setfill(' ') << std::setw(9)
               << AsString(Tree[i][j][k].Overtime1) << " ";
        Stream << std::setfill(' ') << std::setw(9)
               << AsString(Tree[i][j][k].Overtime2) << " ";
        Stream << std::setfill(' ') << std::setw(9)
               << AsString(Tree[i][j][k].Travel) << std::endl;
      }
    }
  }
  Stream << std::setfill('-') << std::setw(70) << "-" << std::endl;
}*/

void TPrint::PrintTableRow(const std::string& type, TTime time) throw()
{
  Stream << std::setfill(' ') << std::setw(49) 
         << std::setiosflags(std::ios::left) << type 
         << std::resetiosflags(std::ios::left) << std::setfill(' ')
         << std::setw(7) 
         << time.GetAsString()
         << " " << std::setfill(' ') << std::setw(12) 
         << std::setiosflags(std::ios::fixed) << std::setprecision(2)
         << time.GetAsDouble()
         << std::endl;
}

void TPrint::PrintTableRow(const std::string& str1, std::string str2) throw()
{
  std::string temp;
  int index = 0;

  Stream << " " << std::setfill(' ') << std::setw(12) 
         << std::setiosflags(std::ios::left) << str1;
  if (str2.size() > 58) {
    temp = str2;
    index = temp.rfind(" ", 58);
    temp.erase(0, index + 1);
    if (temp[0] == ' ') {
      temp.erase(0, 1);
    }
    str2.resize(index + 1);
    Stream << std::setfill(' ') << std::setw(58) << str2
           << std::endl << std::setfill(' ') << std::setw(13)	<< " " 
           << std::setfill(' ') << std::setw(58)<< temp 
           << std::endl << std::resetiosflags(std::ios::left);
  }
  else {
    Stream << std::setfill(' ') << std::setw(58) << str2
           << std::endl << std::resetiosflags(std::ios::left);
  }
}

void TPrint::PrintTableRow(const std::string& type,
                           int time, bool isTime) throw()
{
  Stream << std::setfill(' ') << std::setw(49) 
         << std::setiosflags(std::ios::left) << type 
         << std::resetiosflags(std::ios::left);
	
  if (isTime) {
    Stream << std::setfill(' ') << std::setw(7) 
           << AsString(time)
           << " " << std::setfill(' ') << std::setw(12) 
           << std::setiosflags(std::ios::fixed)
           << std::setprecision(2) << AsDouble(time)
           << std::endl;
  }
  else {
    Stream << std::setfill(' ') << std::setw(20) 
           << std::setiosflags(std::ios::fixed)
           << std::setprecision(2) << AsDouble(time)
           << std::endl;
  }
}

void TPrint::PrintTableRow(const std::string& type, double d) throw()
{
  Stream << std::setfill(' ') << std::setw(49) 
         << std::setiosflags(std::ios::left) << type 
         << std::resetiosflags(std::ios::left)
         << std::setfill(' ') << std::setw(20) 
         << std::setiosflags(std::ios::fixed) << std::setprecision(2) << d
         << std::endl;
}

void TPrint::PrintLine(char fillChar, int width) throw()
{
  Stream << std::setfill(fillChar) << std::setw(width)
         << fillChar << std::endl;
}

void TPrint::PrintTableHeader(const std::string& text) throw()
{
  Stream << std::endl << " " << text << std::endl;
}

void TPrint::PrintTableRow(const std::string& date,
                           int total, int flex, 
                           int normal, int o1,
                           int o2, int travel) throw()
{
  Stream << date
         << std::setfill(' ') << std::setw(10) << AsString(total)
         << std::setfill(' ') << std::setw(10) << AsString(flex)
         << std::setfill(' ') << std::setw(10) << AsString(normal)
         << std::setfill(' ') << std::setw(10) << AsString(o1)
         << std::setfill(' ') << std::setw(10) << AsString(o2)
         << std::setfill(' ') << std::setw(9)  << AsString(travel)
         << std::endl;
}

void TPrint::PrintWarning(bool isWarning) throw() 
{
  char c = ' ';
  if (isWarning) {
    c = '*';
  }
  Stream << c;
}
