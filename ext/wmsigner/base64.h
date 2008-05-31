#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef __BASE64_DEFINED___
#define __BASE64_DEFINED___
#endif /* __BASE64_DEFINED___ */ 

#define ENCODE  0
#define DECODE  1

#define CODE_ERR        0

#ifndef TRUE
#define TRUE            1
#endif
#ifndef FALSE
#define FALSE           0
#endif

#define MAXBUFFER       4096  //  Don`t change this parameter !!!
#define READBYTES       3072  //  Don`t change this parameter !!!

/* Bits BASE64 structure */
typedef struct __Bits64__ {
  unsigned b3 : 6; /* 1 Base 64 character  */
  unsigned b2 : 6; /* 2 Base 64 character  */
  unsigned b1 : 6; /* 3 Base 64 character  */
  unsigned b0 : 6; /* 4 Base 64 character  */
} BITS, *BITSPTR;

/* Union of Bits & Bytes */
typedef union __Base64__ {
  char a[3]; /* Byte array in the case  */
  BITS b;    /* Bits fields in the case */
} BASE64;

/* Base_64 index structure */

typedef struct __index64__ {
  char Ch;
  int Id;
} INDEX64, *INDEX64PTR;

/* Prototypes */                                                                                                                           
size_t code64( int job, char *buf_ascii, size_t ascii_size, char *buf_64, size_t buf_64_size );                                            
int idx64( char ch ); 

