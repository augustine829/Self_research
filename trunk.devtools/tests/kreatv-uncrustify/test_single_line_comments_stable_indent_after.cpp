// Testing indentation of inline comments
// (indent_relative_single_line_comments doesn't work as one might expect)

class A
{
public:
  void myfunction(int arg1, // This argument 1
                  int arg2, // This comment 2
                  int arg3,  // This comment 3
                  int arg4,   // This comment 4
                  int arg5,    // This comment 5
                  int arg6,     // This comment 6
                  int arg7,      // This comment 7
                  int arg8,       // This comment 8
                  int arg9);
};
