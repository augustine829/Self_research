// DISABLED: Requires long_line_indent.patch which is currently disabled
// Testing wrapping of long strings

class A
{
public:
  void afunction()
  {
    calltoaverylongfunctionfunctionfunctioncuntionfunction("Hej", "This string is too long to be indented correctly");
    calltoaverylongfunctionfunctionfunctioncuntionfunction("Hej2",
         "!This string is too long to be indented correctly",
   int k);
    calltoaverylongfunctionagainfunctionthatistolong(int alongargument, int anotherlongargument, int b);
    calltoaverylongfunctionagainfunctionthatistolong(int alongargument, int anotherlongargumentthatwillnotwork, int b);
    calltoaverylongfunctionagainfunctionthatistolong(int alongargument,
                                   int donottouchthisargumentitwillnotfit,
                                     int b,
                                               calltofunc(val1, val2,
                      val3isveryveryveryveryverylonglong));
  }
};
