/*
 *--------------------------------------------------------------------
 *
 * Parser.h --
 *
 * Klassen TParser
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef PARSER_H
#define PARSER_H

#include "base/VerboseException.h"
#include "records/Record.h"
#include "Scanner.h"
#include <map>

class TParser
{
private:
  TRecord Record;
  TScanner Scanner;

public:
  TParser(const char* infile) throw(TVerboseException);
  ~TParser();
  void GetHeader() throw(TVerboseException);
  void GetTimeReport() throw(TVerboseException);
  TRecord GetRecord() throw();
};

inline TRecord TParser::GetRecord() throw()
{
  return Record;
}
#endif
