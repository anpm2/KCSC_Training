#include <stdlib.h>
#include <stdio.h>

int fn1(void), fn2(void), fn3(void), fn4 (void);

int main( void ){
   _onexit( fn1 );
   _onexit( fn2 );
   _onexit( fn3 );
   _onexit( fn4 );
   printf( "This is executed first.\n" );
}

int fn1(){
   printf( "next.\n" );
   return 0;
}

int fn2(){
   printf( "executed " );
   return 0;
}

int fn3(){
   printf( "is " );
   return 0;
}

int fn4(){
   printf( "This " );
   return 0;
}