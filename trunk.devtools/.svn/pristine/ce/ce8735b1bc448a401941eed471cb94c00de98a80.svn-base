// DISABLED: unfortunate side effect of sp_addr and sp_after_type
// Testing & and * together with macros

class MySpecialType
{
};

void function(const MySpecialType & a)
{
  BOOST_FOREACH(const MySpecialType & b, list) {
  }

  BOOST_FOREACH(const MySpecialType& c, list) {
  }
}
