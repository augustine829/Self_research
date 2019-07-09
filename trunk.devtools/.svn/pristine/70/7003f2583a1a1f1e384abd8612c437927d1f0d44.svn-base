/*
 *--------------------------------------------------------------------
 *
 * Record.h --
 *
 * Klassen TRecord
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef RECORD_H
#define RECORD_H

#include "Row.h"
#include "time/Time.h"
#include <vector>
#include <string>

class TRecord
{
private:
  std::vector<TRow> Rows;

public:
  std::string Name;
  std::string InMoney;
  TTime InFlex;
  TTime InKomp;
  TTime OutKomp;
  TTime InOvertime1;
  TTime InOvertime2;
  int Year;
  int Month;

  TRecord() throw();
  std::vector<TRow> GetRows() const throw();
  void SetRow(const TRow& row) throw();
  TRecord& operator= (const TRecord& r) throw ();
  bool GetInMoney() const throw ();
};

inline void TRecord::SetRow(const TRow& row) throw()
{
  Rows.push_back(row);
}

inline std::vector<TRow> TRecord::GetRows() const throw()
{
  return Rows;
}
#endif
