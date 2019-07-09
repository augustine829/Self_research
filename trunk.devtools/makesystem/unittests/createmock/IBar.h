#ifndef IBAR_H
#define IBAR_H

class IBar
{
public:
  virtual ~IBar() {}

  virtual unsigned long Barson(const std::string& x) = 0;
};

#endif
