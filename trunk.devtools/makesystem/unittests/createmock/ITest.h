#ifndef ITEST_H
#define ITEST_H

#include "IFoo.h"
#include "IBar.h"

class TApa;

namespace Kvast {

namespace Fening
{

class EXPORT IApelsin : public IFoo,
                        public IBar, public IFie
{
private:
  enum TDjur
  {
    Tiger,
    Bear,
    Beaver
  };

public:
  virtual ~IApelsin() throw() {}

  struct TTree
  {
    int X;
    int Y;
    explicit TTree(int x) : X(x), Y(0) {}
  };

  // spunk
  virtual const int* const Skala(int x, const std::vector<std::string>& y,
                                 // foo
                                 std::string z = "flaska" /* bar */) = 0;

  class LOCAL IApelsinObserver : public IBar
  {
  public:
    virtual ~IApelsinObserver() throw (TCitrus) {}
    /* FLINK
     * FLUNK */
    virtual unsigned int OnClimb(int x) const throw(TApa) = 0; // flap
    /*
    virtual unsigned int OnClimbRemoved(int x) const throw(TApa) = 0;
    */
    // virtual unsigned int OnClimbRemovedAgain(int x) const throw(TApa) = 0;
  };

  /*
  class IBananObserver
  {
    public:
    virtual unsigned int OnEat(int x) const throw(TApa) = 0;
  };
  */

  virtual void Eat(std::string foo) const
    __attribute__((format (printf, 17, 42))) = 0;
  virtual TApa& Eater(std::string foo) throw(TApa&) const = 0;
  virtual void EatFunc1(const std::function<void ()> &food)
    throw () __attribute__ ((warn_unused_result)) = 0;
  virtual void EatFunc2(
    const std::function<bool (const IFish*)> &food) = 0;
};

class IBanan
{
public:
  virtual ~IBanan() {}

  virtual unsigned long long Skala(unsigned long long x,
                                   TBeaver<int> zzz) = 0;
};

} // namespace Fening

} // namespace Kvast

#endif
