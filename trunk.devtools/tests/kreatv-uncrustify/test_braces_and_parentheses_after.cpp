// 3.8 Braces and Parentheses + 3.9 Else Clauses

namespace {
enum TMyEnum {
}
namespace {
}
}

void Function()
{
  int a;
  int b;
  if (a == b) {
    a = 0;
  }
  else if (a < b) {
    a = 1;
  }
  if (b < a) {
    b = a;
  }
  else {
    a = 2;
  }
  for (; a < 3; ++a) {
    b = a;
  }
  while (a) {
    a--;
  }
  switch (a)
  case 2:
    break;
  for (int i = 0; i < 3; ++i) {
    std::cout << "Wrong indentation" << std::endl;
  }
}

class TMyClass
{
public:
  int x;
};

int RetFunc()
{
  int* s;
  return 1 - 2;
}
