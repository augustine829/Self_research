#include "Scanner.h"
#include <vector>
#include <iostream>

TScanner::TScanner(const char* filename)
{
  if (std::string(filename) == "-") {
    File = &std::cin;
    Filename = "<Standard input>";
  }
  else {
    std::ifstream* file = new std::ifstream(filename);
    if (!file->is_open()) {
      throw TVerboseException(0, "Could not open file");
    }
    File = file;
    Filename = filename;
  }

  LineNumber = 1;
}

TScanner::~TScanner() 
{
  if (File != &std::cin) {
    delete File;
  }
}

unsigned char TScanner::PeekChar()
{
  return static_cast<unsigned char>(File->peek());
}

void TScanner::SkipChar()
{
  CurrentLine += static_cast<unsigned char>(File->get());
}

bool TScanner::PeekEndOfFile()
{
  return File->peek() < 0;
}

bool TScanner::PeekEndOfLine()
{
  return File->peek() < 0 || File->peek() == '\n';
}

void TScanner::SkipWhiteSpace()
{
  while(!PeekEndOfFile()
        && (PeekChar() == ' ' || PeekChar() == '\t' ||
            PeekChar() == '\n' || PeekChar() == '\r' || PeekChar() == '#')) {
    if (PeekChar() == '\n') {
      LineNumber++;
    }
    else if (PeekChar() == '#') {
      // Comment, consume characters until newline
      while (!PeekEndOfFile() && PeekChar() != '\n') {
        SkipChar();
      }
      continue;
    }
    SkipChar();
  }
}

std::string TScanner::GetText()
{
  std::string result = "";
  char c;

  SkipWhiteSpace();
  while (c = PeekChar(), (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
         c == 'å' || c == 'ä' || c == 'ö' ||
         c == 'Å' || c == 'Ä' || c == 'Ö') {
    result += c;
    SkipChar();
  }
  return result;
}

std::string TScanner::GetActivity()
{
  std::string result = "";
  char c;

  SkipWhiteSpace();
  while (c = PeekChar(), (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
         c == 'å' || c == 'ä' || c == 'ö' ||
         c == 'Å' || c == 'Ä' || c == 'Ö' || 
         (c >= '0' && c <= '9') || c == '.' || c == '-') {
    result += c;
    SkipChar();
  }
  return result;
}

void TScanner::SkipText(const std::string& text) throw(TVerboseException)
{
  std::string result;

  result = GetText();
  if (result != text) {
    throw TVerboseException(0, (std::string("Parse error in ")
                                + GetFileContext()).c_str());
  }
}

void TScanner::SkipChar(unsigned char c) throw(TVerboseException)
{
  SkipWhiteSpace();
  if (c != static_cast<unsigned char>(File->get())) {
    throw TVerboseException(0, (std::string("Parse error in ")
                                + GetFileContext()).c_str());
  }
}

int TScanner::GetNumber() throw(TVerboseException)
{
  int res;

  SkipWhiteSpace();
  *File >> res;
  if (File->fail()) {
    throw TVerboseException(0, (std::string("Parse error in ")
                                + GetFileContext()).c_str());
  }
  return res;
}

const std::vector<int> TScanner::GetProjNumber() throw(TVerboseException)
{
  std::string result;
  std::stringstream oss;
  std::vector<int> vector;

  SkipWhiteSpace();
  if (PeekChar() < '0' || PeekChar() > '9') {
    return vector;
  }
  vector.push_back(GetNumber());
  while (PeekChar() == '-') {
    SkipChar();
    vector.push_back(GetNumber());
  }
  if (vector.size() == 0) {
    throw TVerboseException(0, (std::string("Parse error in ")
                                + GetFileContext()).c_str());
  }
  return vector;
}

int TScanner::GetMinutes()
{
  int minutes;

  minutes = GetNumber() * 60;
  if (PeekChar() == ':') {
    SkipChar(':');
    minutes += (minutes < 0 ? -1 : 1 ) * GetNumber();
  }
  return minutes;
}

std::string TScanner::GetFileContext() const
{
  std::ostringstream result;
  result << Filename << " line " << LineNumber;
  return result.str();
}

TTime TScanner::GetHeaderTime() throw(TVerboseException)
{
  int minutes = 0;
  int hours;
  bool isNegative = false;
  
  SkipSpace();
  if (PeekChar() == '-') {
    SkipChar('-');
    isNegative = true;
  }
  hours = GetNumber();
  if (PeekChar() == ':') {
    SkipChar(':');
    minutes = GetNumber();
  }
  
  if (minutes < 0 || minutes > 59) {
    throw TVerboseException(0, (std::string("Parse error in ")
                                + GetFileContext()).c_str());
  }
  return TTime(hours, minutes, isNegative);
}

TTime TScanner::GetTime() throw(TVerboseException)
{
  int minutes = 0;
  int hours;
  bool isNegative = false;

  SkipSpace();
  if (PeekChar() == '-') {
    SkipChar('-');
    isNegative = true;
  }
  hours = GetNumber();
  if (PeekChar() == ':') {
    SkipChar(':');
    minutes = GetNumber();
  }

  if ((minutes < 0 || minutes > 59) || (hours < -24 || hours > 24)) {
    throw TVerboseException(0, (std::string("Parse error in ")
                                + GetFileContext()).c_str());
  }
  return TTime(hours, minutes, isNegative);
}

std::string TScanner::GetComment()
{
  std::string result = "";
  char c;

  SkipSpace();
  while (!PeekEndOfFile() && (c = PeekChar()) != '\n') {
    result += c;
    SkipChar();
  }
  return result;
}


std::string TScanner::GetTimeType()
{
  std::string result;
  char c;
  char d;

  SkipWhiteSpace();
  if (c = PeekChar(), (c == 's' || c == 'S' ||
                       c == 'h' || c == 'H' ||
                       c == 'n' || c == 'N' || c == 'r' || 
                       c == 'R' || c == 'ö' || c == 'Ö' ||
                       c == 'P' || c == 'p' || c == 'Ö')) {
    result += c;
    SkipChar();
  }
  else {
    throw TVerboseException(0, (std::string("Parse error in ")
                                + GetFileContext()).c_str());
  } 
  if (d = PeekChar(), ((c == 'ö' || c == 'Ö') && (d == '1' || d == '2')) ||
      (c == 's' && d == 'j' ) || (c == 'S' && d == 'J')) {
    result += d;
    SkipChar();
  }
  return result;
}

std::string TScanner::GetName()
{
  std::string result = "";
  size_t size = 0;

  if (!PeekEndOfLine()) {
    SkipWhiteSpace();
  }
  else {
    throw TVerboseException(0, (std::string("Parse error in ")
                                + GetFileContext()).c_str());
  }

  result = GetText();
  while (!PeekEndOfLine()) {
    size = result.size();
    result += GetSpecialText();
    if (size == result.size()) {
      result += " " + GetText();
    }
    else {			
      result += GetText();
    }
  }
  return result;
}

std::string TScanner::GetSpecialText()
{
  std::string result;
  char c;

  SkipWhiteSpace();
  if (c = PeekChar(), (c == '!' || c == '-' || 
                       c == '"' || c == '(' || c == ')' || 
                       c == '_' || c == '.' || c == ',')) {
    result += c;
    SkipChar();
  }
  return result;
}

void TScanner::SkipSpace()
{
  while(!PeekEndOfFile() && (PeekChar() == ' ' || PeekChar() == '\t')) {
    SkipChar();
  }
}

void TScanner::SkipComment()
{
  while(!PeekEndOfLine()) {
    SkipChar();
  }
  SkipWhiteSpace();
}
