// Testing & and * together with macros

class MySpecialType
{
};

void function(const MySpecialType& a)
{
  BOOST_FOREACH(const MySpecialType& b, list) {
  }

  BOOST_FOREACH(const MySpecialType& c, list) {
  }
}
