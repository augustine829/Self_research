/*
 *--------------------------------------------------------------------
 *
 * Scanner.h --
 *
 * Klassen TScanner
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#ifndef SCANNER_H
#define SCANNER_H

#include "base/VerboseException.h"
#include "time/Time.h"
#include <string>
#include <vector>
#include <fstream>
#include <sstream>


class TScanner
{
private:
  std::istream* File;
  std::string Filename;
  int LineNumber;
  std::string CurrentLine;

  void ClearLine();

public:
  TScanner(const char* filename);
  ~TScanner();

  bool PeekEndOfFile();
  bool PeekEndOfLine();
  unsigned char PeekChar();
  void SkipChar();
  std::string GetText();
  void SkipText(const std::string& text) throw(TVerboseException);
  void SkipChar(unsigned char c) throw(TVerboseException);
  int GetNumber() throw(TVerboseException);
  const std::vector<int> GetProjNumber() throw(TVerboseException);
  TTime GetTime() throw(TVerboseException);
  TTime GetHeaderTime() throw(TVerboseException);
  int GetMinutes();
  void SkipWhiteSpace();
  std::string GetFileContext() const;
  std::string GetComment();
  std::string GetActivity();
  std::string GetTimeType();
  std::string GetName();
  std::string GetSpecialText();
  void SkipSpace();
  void SkipComment();
};
#endif
