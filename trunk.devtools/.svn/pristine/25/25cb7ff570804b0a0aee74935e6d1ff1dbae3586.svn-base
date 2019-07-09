/*
 *--------------------------------------------------------------------
 *
 * Parser.cpp --
 *
 * Klassen TParser
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
#include "Parser.h"
#include <iostream>
#include <iomanip>
#include <sstream>
#include <algorithm>
#include <ctime>

TParser::TParser(const char* inFile) throw(TVerboseException)
  : Scanner(inFile)
{
  // Empty
}

TParser::~TParser()
{
  // Empty
}

void TParser::GetHeader() throw(TVerboseException)
{
  // Anledningen till alla separata if-satser är
  // att Scanner.GetFileContext() ska returnera rätt rad
  std::string name;
  TTime outFlex;
  time_t sysTime;
  struct tm* today;

  // Get system time
  time(&sysTime);
  today = localtime(&sysTime);   

  Scanner.SkipText("namn");
  Scanner.SkipChar('=');
  Record.Name = Scanner.GetName();

  Scanner.SkipText("år");
  Scanner.SkipChar('=');
  Record.Year = Scanner.GetNumber();
  if (Record.Year != (today->tm_year + 1900)) {
    std::cout << "WorkFlex2000 warning: It's year "
              << (today->tm_year + 1900) << " today." 
              << std::endl << std::endl;
  }

  Scanner.SkipText("månad");
  Scanner.SkipChar('=');
  Record.Month = Scanner.GetNumber();
  if (Record.Month < 0 || Record.Month >= 13) {
    throw TVerboseException(0, (std::string("Invalid month ")
                                + Scanner.GetFileContext()));
  }
 
  Scanner.SkipText("inflex");
  Scanner.SkipChar('=');
  Record.InFlex = Scanner.GetHeaderTime();
  
  Scanner.SkipText("komptidsuttag");
  Scanner.SkipChar('=');
  Record.OutKomp = Scanner.GetHeaderTime();
  if (Record.OutKomp.IsNegative()) {
    throw TVerboseException(0, (std::string("Negative value in ")
                                + Scanner.GetFileContext()));
  }  

  Scanner.SkipText("ingående");
  Scanner.SkipChar('k');
  Scanner.SkipText("omptid");
  Scanner.SkipChar('=');
  Record.InKomp = Scanner.GetHeaderTime();
  if (Record.InKomp.IsNegative()) {
    throw TVerboseException(0, (std::string("Negative value in ")
                                + Scanner.GetFileContext()));
  }  

  Scanner.SkipText("ingående");
  Scanner.SkipChar('ö');
  Scanner.SkipText("vertid");
  Scanner.SkipChar('1');
  Scanner.SkipChar('=');
  Record.InOvertime1 = Scanner.GetHeaderTime();
  if (Record.InOvertime1.IsNegative()) {
    throw TVerboseException(0, (std::string("Negative value in ")
                                + Scanner.GetFileContext()));
  }

  Scanner.SkipText("ingående");
  Scanner.SkipChar('ö');
  Scanner.SkipText("vertid");
  Scanner.SkipChar('2');
  Scanner.SkipChar('=');
  Record.InOvertime2 = Scanner.GetHeaderTime();
  if (Record.InOvertime2.IsNegative()) {
    throw TVerboseException(0, (std::string("Negative value in ")
                                + Scanner.GetFileContext()));
  }
  
  Scanner.SkipText("övertid");
  Scanner.SkipChar('i');
  Scanner.SkipChar('p');
  Scanner.SkipText("engar");
  Scanner.SkipChar('=');
  Record.InMoney = Scanner.GetText();
  if (Record.InMoney != "ja" && Record.InMoney != "JA" &&
      Record.InMoney != "nej" && Record.InMoney != "NEJ") {
    throw TVerboseException(0, (std::string("Value should be ja/nej ")
                                + Scanner.GetFileContext()));
  }
}

void TParser::GetTimeReport() throw(TVerboseException)
{
  std::vector<int> vector;
  std::string activity = "";
  std::string type;
  std::string weekday;
  std::string comment;
  std::string lastWeekday = "";
  std::string lastType = "";
  int year;
  int month;
  int day;
  TDate lastDate;	
  TTime lastToTime;

  while(!Scanner.PeekEndOfFile()) {
    TTime fromTime;
    TTime toTime;

    Scanner.SkipWhiteSpace();		
    if (Scanner.PeekChar() == ';') {
      // Skip a "row" comment starting with ';'
      Scanner.SkipComment();
    }
    else {
      //Parse a row
      year = Scanner.GetNumber();
      Scanner.SkipChar('-');
      month = Scanner.GetNumber();
      Scanner.SkipChar('-');
      day = Scanner.GetNumber();
      weekday = Scanner.GetText();
      fromTime = Scanner.GetTime();
      Scanner.SkipChar('-');
      toTime = Scanner.GetTime();
      type = Scanner.GetTimeType();
      vector = Scanner.GetProjNumber();
      if (vector.size() == 0) {
        activity = Scanner.GetActivity();
      }
      comment = Scanner.GetComment();
      Scanner.SkipWhiteSpace();
			
      // Check for parser errors
      if (Record.Year != year || Record.Month != month) {
        std::ostringstream oss;
        oss << "The month or/and the year specified in the header" << std::endl
            << "does/do not match the the time report" << std::endl;
        throw TVerboseException(0, oss.str());
      }
			
      if (toTime.GetAsMinutes() - fromTime.GetAsMinutes() < 0) {
        std::ostringstream oss;
        oss << "Negative time in " << Scanner.GetFileContext() << std::endl;
        throw TVerboseException(0, oss.str());
      }
			
      if ("mån" != weekday &&
          "tis" != weekday &&
          "ons" != weekday &&
          "tors" != weekday &&
          "tor" != weekday &&
          "fre" != weekday &&
          "lör" != weekday &&
          "sön" != weekday &&
          "röd" != weekday) {
        std::ostringstream oss;
        oss << "Wrong weekday " << Scanner.GetFileContext() << std::endl;
        throw TVerboseException(0, oss.str());
      }
			
      if (lastDate == TDate(year, month, day)
          && lastWeekday != weekday
          && weekday != "röd") {
        std::ostringstream oss;
        oss << "All rows with the same date cannot have different weekdays." 
            << std::endl << Scanner.GetFileContext() << std::endl;
        throw TVerboseException(0, oss.str());
      }

      if ((lastDate == TDate(year, month, day)) && 
          (type == "s" || type == "S" || 
           lastType == "s" || lastType == "S")) { 
        std::ostringstream oss;
        oss << "When the type vacation, 's', is used you cannot" << std::endl
            << "report any other time that day." 
            << std::endl << Scanner.GetFileContext() << std::endl;
        throw TVerboseException(0, oss.str());
      }

      if ((lastDate == TDate(year, month, day)) && (lastToTime > fromTime)) {
        std::ostringstream oss;
        oss << "Intervals are not supposed to overlap." 
            << std::endl << Scanner.GetFileContext() << std::endl;
        throw TVerboseException(0, oss.str());
      }
      lastType = type;
      lastToTime = toTime;
      lastDate = TDate(year, month, day);
      lastWeekday = weekday;
			
      // Add zeros to projNumber vector
      for (int i = vector.size(); i < 3; i++) {
        vector.push_back(0);
      }
			
      Record.SetRow(TRow(TDate(year, month, day), 
                         weekday, fromTime, toTime,
                         type,
                         vector[0],
                         vector[1],
                         vector[2], activity, comment));
    }
  }
}
