// 3.2 Indentation

void function()
{
  int a = 0;
  if (a == 0) {
    a = 2;
    while (true) {
      a = 0;
    }
  }
}

namespace {
namespace {
void func()
{
  int a;
}
int b;
}
}

template<typename A>
class MyClass
{
protected:
  int x;
  A b;

public:
  void func()
  {
    switch (b) {
    case 3:
      break;
    }
  }
};
