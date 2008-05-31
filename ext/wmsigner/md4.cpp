#include "stdafx.h"
#include <stdio.h>
#include "md4.h"
#include "cmdbase.h"

#define TRUE  1
#define FALSE 0

#define I0  0x67452301L
#define I1  0xefcdab89L
#define I2  0x98badcfeL
#define I3  0x10325476L
#define C2  013240474631L
#define C3  015666365641L

#define fs1  3
#define fs2  7
#define fs3 11
#define fs4 19
#define gs1  3
#define gs2  5
#define gs3  9
#define gs4 13
#define hs1  3
#define hs2  9
#define hs3 11
#define hs4 15


#define f(X,Y,Z)             ((X&Y) | ((~X)&Z))
#define g(X,Y,Z)             ((X&Y) | (X&Z) | (Y&Z))
#define h(X,Y,Z)             (X^Y^Z)
#define rot(X,S)             (tmp=X,(tmp<<S) | (tmp>>(32-S)))
#define ff(A,B,C,D,i,s)      A = rot((A + f(B,C,D) + X[i]),s)
#define gg(A,B,C,D,i,s)      A = rot((A + g(B,C,D) + X[i] + C2),s)
#define hh(A,B,C,D,i,s)      A = rot((A + h(B,C,D) + X[i] + C3),s)

void MDprint(MDptr MDp)
{
  int i,j;
  for (i=0;i<4;i++)
    for (j=0;j<32;j=j+8)
      printf("%02x",(MDp->buffer[i]>>j) & 0xFF);
}

void MDbegin(MDptr MDp)
{
  int i;
  MDp->buffer[0] = I0;
  MDp->buffer[1] = I1;
  MDp->buffer[2] = I2;
  MDp->buffer[3] = I3;
  for (i=0;i<8;i++)
    MDp->count[i] = 0;
  MDp->done = 0;
}

#define revx { t = (*X << 16) | (*X >> 16); *X++ = ((t & 0xFF00FF00L) >> 8) | ((t & 0x00FF00FFL) << 8); }

void MDreverse(Word32Type *X)
{
  register Word32Type t;
  revx; revx; revx; revx; revx; revx; revx; revx;
  revx; revx; revx; revx; revx; revx; revx; revx;
}

static void MDblock(MDptr MDp, Word32Type *X)
{
  register Word32Type tmp, A, B, C, D;
#ifndef LOWBYTEFIRST
  MDreverse(X);
#endif
  A = MDp->buffer[0];
  B = MDp->buffer[1];
  C = MDp->buffer[2];
  D = MDp->buffer[3];
  ff(A , B , C , D ,  0 , fs1);
  ff(D , A , B , C ,  1 , fs2);
  ff(C , D , A , B ,  2 , fs3);
  ff(B , C , D , A ,  3 , fs4);
  ff(A , B , C , D ,  4 , fs1);
  ff(D , A , B , C ,  5 , fs2);
  ff(C , D , A , B ,  6 , fs3);
  ff(B , C , D , A ,  7 , fs4);
  ff(A , B , C , D ,  8 , fs1);
  ff(D , A , B , C ,  9 , fs2);
  ff(C , D , A , B , 10 , fs3);
  ff(B , C , D , A , 11 , fs4);
  ff(A , B , C , D , 12 , fs1);
  ff(D , A , B , C , 13 , fs2);
  ff(C , D , A , B , 14 , fs3);
  ff(B , C , D , A , 15 , fs4);
  gg(A , B , C , D ,  0 , gs1);
  gg(D , A , B , C ,  4 , gs2);
  gg(C , D , A , B ,  8 , gs3);
  gg(B , C , D , A , 12 , gs4);
  gg(A , B , C , D ,  1 , gs1);
  gg(D , A , B , C ,  5 , gs2);
  gg(C , D , A , B ,  9 , gs3);
  gg(B , C , D , A , 13 , gs4);
  gg(A , B , C , D ,  2 , gs1);
  gg(D , A , B , C ,  6 , gs2);
  gg(C , D , A , B , 10 , gs3);
  gg(B , C , D , A , 14 , gs4);
  gg(A , B , C , D ,  3 , gs1);
  gg(D , A , B , C ,  7 , gs2);
  gg(C , D , A , B , 11 , gs3);
  gg(B , C , D , A , 15 , gs4);
  hh(A , B , C , D ,  0 , hs1);
  hh(D , A , B , C ,  8 , hs2);
  hh(C , D , A , B ,  4 , hs3);
  hh(B , C , D , A , 12 , hs4);
  hh(A , B , C , D ,  2 , hs1);
  hh(D , A , B , C , 10 , hs2);
  hh(C , D , A , B ,  6 , hs3);
  hh(B , C , D , A , 14 , hs4);
  hh(A , B , C , D ,  1 , hs1);
  hh(D , A , B , C ,  9 , hs2);
  hh(C , D , A , B ,  5 , hs3);
  hh(B , C , D , A , 13 , hs4);
  hh(A , B , C , D ,  3 , hs1);
  hh(D , A , B , C , 11 , hs2);
  hh(C , D , A , B ,  7 , hs3);
  hh(B , C , D , A , 15 , hs4);
  MDp->buffer[0] += A;
  MDp->buffer[1] += B;
  MDp->buffer[2] += C;
  MDp->buffer[3] += D;

#ifndef LOWBYTEFIRST
  MDreverse(X);
#endif
}

void MDupdate(MDptr MDp, unsigned char *X, Word32Type count)
{
  int i, byte ;
  Word32Type tmp, bit, mask;
  unsigned char XX[64];
  unsigned char *p;
  if(count == 0 && MDp->done)
    return;
  if (MDp->done)
  {
    return;
  }
  tmp = count;
  p = MDp->count;
  while (tmp)
  {
    tmp += *p;
    *p++ = (unsigned char) tmp;
    tmp = tmp >> 8;
  }
  if (count == 512)
  {
    MDblock(MDp,(Word32Type *)X);
  }
  else
    if (count > 512)
    {
      return;
    }
    else
    {
      byte = (int) count >> 3;
      bit =  count & 7;
      for (i=0;i<=byte;i++)
        XX[i] = X[i];
      for (i=byte+1;i<64;i++)
        XX[i] = 0;
      mask = 1 << (7 - bit);
      XX[byte] = (unsigned char) (XX[byte] | (unsigned char)mask) & ~((unsigned char)mask - 1);
      if (byte <= 55)
      {
        for (i=0;i<8;i++)
          XX[56+i] = MDp->count[i];
        MDblock(MDp,(Word32Type *)XX);
      }
      else
      {
        MDblock(MDp,(Word32Type *)XX);
        for (i=0;i<56;i++)
          XX[i] = 0;
        for (i=0;i<8;i++)
          XX[56+i] = MDp->count[i];
        MDblock(MDp,(Word32Type *)XX);
      }
      MDp->done = 1;
    }
}
//----
