/*
 *--------------------------------------------------------------------
 *
 * Customer.cpp --
 *
 * Klassen TCustomer
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */
#include "Customer.h"

TCustomer::TCustomer() throw() 
  : Number(0),
    //Travel(0),
    Overtime1(0),
    Overtime2(0),
    Normal(0) 
{
  // Empty
}

TCustomer::TCustomer(int num, //int t,
                     int o1, int o2, int nor) throw()
  : Number(num),
    //Travel(t),
    Overtime1(o1),
    Overtime2(o2),
    Normal(nor) 
{
  // Empty
}

void TCustomer::AddHours(TCustomer c) throw() 
{
  //Travel += c.Travel;
  Overtime1 += c.Overtime1;
  Overtime2 += c.Overtime2;
  Normal += c.Normal;
}

