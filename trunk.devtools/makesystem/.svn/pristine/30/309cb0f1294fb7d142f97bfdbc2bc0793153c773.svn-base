//@ The correct count of effective lines is : 12

#include <cstdlib>
#define  XXX "xxxx"

int main()    // effective line
{

// ===== CASE 1 ======

/* 
 some comments
*/

/* some comments */

/* effective line */ int a = 2;

 int b = 2; /* effective line */

 int c = 2; /* effective line */ int d = 2; 
 
/* effective line */ int e = 2; /* effective line */


/* ineffective line /* int f = 2;
 effective line */ int f = 3;

/* ineffective line /* int g = 2;
   ineffective line */ // int g = 3;


// ===== CASE 2 ======

/*      /*
effective line */ int h = 1; /*
                               /**/

 /* ineffective line /* h = a + b 
    h = b -a; */


// ===== CASE 3 ======
/*      /*
//effective line */ int z = 1;


// ===== CASE 4 ======

  /* int y = 1; /* ineffective line */ /*
  */ int y = 1; /* effective line */ int x = 0;/* */

// ===== CASE 5 ======

/*
 */ int w = 1; /* effective line */  /*
               /* some comments */

// ===== CASE 6 ======
  /* int u = 1; /* ineffective line */ /*
  */ int u = 1; /* effective line */ //int u = 0;/* */


// ===== CASE 7 ======

  /* int v = 1; /* ineffective line */ /*
  */ //int v = 1; /* ineffective line */ int t = 0;/* */


// ===== CASE 8 ======

  /* int s = 1; /* ineffective line */ /*
  */ /*int s = 1;*/ /* ineffective line */ //int r = 0;/* */


// ===== CASE 9 ======

  /* int q = 1; /* ineffective line */  /* q = a + b 
     q = b -a; */

// ===== CASE 10 ======

  /* int p = 1; /* ineffective line */ /*
     p = c;     /* ineffective line */


  return a + b + c + d + e + f + h + z + y + x + w + u;
}
