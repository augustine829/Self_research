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


class __attribute__ ((visibility("default"))) IOrange : public IFoo
{
public:
  virtual ~IOrange() throw() {}

  class __attribute__ ((visibility("hidden"))) IOrangeObserver
  {
  public:
    #pragma GCC visibility push(default)
    virtual ~IOrangeObserver() throw (TCitrus) {}
    #pragma GCC visibility pop
    virtual unsigned int OnClimb(int x) const throw(TMonkey) = 0; // flap
  };

  #pragma GCC visibility push(hidden)
  virtual void Eat(std::string foo) const = 0;
  virtual TMonkey& Eater(std::string foo) const throw(TMonkey&) = 0;
  #pragma GCC visibility pop
};


__attribute__ ((visibility("default"))) void Exported();
void Exported2()__attribute__ ((visibility("default")));

__attribute__ ((visibility("hidden"))) void Hidden();
void Hidden2() __attribute__ ((visibility("hidden")));

#pragma GCC visibility push(default)
void Foo();
#pragma GCC visibility pop

#pragma GCC visibility push(hidden)
void Bar();
#pragma GCC visibility pop

#endif
