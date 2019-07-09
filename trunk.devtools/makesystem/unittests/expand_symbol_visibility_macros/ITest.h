#ifndef ITEST_H
#define ITEST_H

#include <string>

#ifndef EXPORT
#define EXPORT
#endif

class TMonkey {};
class TCitrus {};


class IFoo
{
public:
  virtual ~IFoo() {}
};


class EXPORT IOrange : public IFoo
{
public:
  virtual ~IOrange() throw() {}

  class LOCAL IOrangeObserver
  {
  public:
    EXPORT_BEGIN
    virtual ~IOrangeObserver() throw (TCitrus) {}
    EXPORT_END
    virtual unsigned int OnClimb(int x) const throw(TMonkey) = 0; // flap
  };

  LOCAL_BEGIN
  virtual void Eat(std::string foo) const = 0;
  virtual TMonkey& Eater(std::string foo) const throw(TMonkey&) = 0;
  LOCAL_END
};


EXPORT void Exported();
void Exported2()EXPORT;

LOCAL void Hidden();
void Hidden2() LOCAL;

EXPORT_BEGIN
void Foo();
EXPORT_END

LOCAL_BEGIN
void Bar();
LOCAL_END

#endif
