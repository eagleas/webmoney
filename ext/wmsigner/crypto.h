#ifndef __CRYPTO_H__
#define __CRYPTO_H__
#include "stdafx.h"

#ifndef keybits
  #define ebits 48
  #define keybits 528
#endif

unsigned int CrpB(char* crp, char* p, int len, const unsigned short * e, const unsigned short *n, short KeyBits=keybits);
unsigned int DCrpB(char* dcrp, int* dlen, char* c, int len, const unsigned short * d, const unsigned short *n, short KeyBits=keybits);
unsigned int GetCLenB(int len, const unsigned short *n, short KeyBits=keybits);
unsigned int GetKeyBaseB(const unsigned short *n);
unsigned int GetKeyBase(const unsigned short *n);

#endif
//---
