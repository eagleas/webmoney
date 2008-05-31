#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include "crypto.h"
#include "rsalib1.h"
#include <memory.h>


unsigned short SwitchIndian(unsigned short n1);

unsigned int GetCLenB(int len, const unsigned short *n, short KeyBits)
{
  CRSALib rsalib((KeyBits + 15)>> 4);
  rsalib.set_precision((KeyBits + 15) >> 4);
  int blocksize = rsalib.significance((unsigned short *)n);
  int workblocksize = blocksize-1;
  int len_and_sizeW = (len+sizeof(short)+1) >> 1;
  int hvost = (len_and_sizeW)%workblocksize;
  if (hvost) hvost = 1;
  int newLen = (((len_and_sizeW) / (workblocksize)) + hvost) * blocksize;
  return (newLen*2);
}

unsigned int CrpB(char* crp, char* p, int len, const unsigned short * e, const unsigned short *n, short KeyBits)
{

  CRSALib rsalib((KeyBits + 15)>> 4);
  rsalib.set_precision((KeyBits + 15) >> 4);
  int blocksize = rsalib.significance((unsigned short *)n)*2;
  int workblocksize = blocksize-2;
  int ostb = 2;
  int i=0, stP=0, endP=0, stC=0;
  char pb[CRSALib::MAX_UNIT_PRECISION*2], cb[CRSALib::MAX_UNIT_PRECISION*2];
  char *buf = (char *)malloc(len+ostb);
  memcpy(buf+sizeof(short), p, len);
  *(short*)buf = SwitchIndian((short)len);
  int iLen = len+sizeof(short);
  stP = 0;
  stC = 0;
  int res = 0, res1 = 0;

  do
  {
    memset(cb, 0, CRSALib::MAX_UNIT_PRECISION*2);
    memset(pb, 0, CRSALib::MAX_UNIT_PRECISION*2);

    endP = ((workblocksize < iLen) ? workblocksize : iLen);
    memcpy(pb, buf+stP, endP);
    for(int h=0;h<endP/2;h++)
    {
    	((unsigned short*)pb)[h] = SwitchIndian(((unsigned short*)pb)[h]);
    }
#ifdef _DEBUG
    for(int h=0;h<endP/2;h++)
    {
    	printf("X:%d ", ((unsigned short*)pb)[h]);
    }
#endif

    if ((res = rsalib.mp_modexp((unsigned short*)cb, (unsigned short*)pb, (unsigned short *)e, (unsigned short *)n)) != 0)
    {
      res1 = res;
    }

	memcpy(crp+stC, cb, blocksize);

    stP += endP;
    stC += blocksize;
    iLen -= (workblocksize);
  } while (iLen > 0);

  free(buf);

  return GetCLenB(len, n);
}

unsigned int DCrpB(char* dcrp, int* dlen, char* c, int len, const unsigned short * d, const unsigned short *n, short KeyBits)
{
  CRSALib rsalib((KeyBits + 15)>> 4);
  rsalib.set_precision((KeyBits + 15) >> 4);
  int blocksize = rsalib.significance((unsigned short *)n)*2;
  if (0==blocksize)
  {
    *dlen = 0;
    return 0;
  }
  if (len < blocksize)
  {
    *dlen = 0;
    return 0;
  }
  int workblocksize = blocksize-2;
  int rcLen = 0, iLen = len;
  int stP = 0, stC = 0;

  char *buf = (char *)malloc(len);
  memset(buf, 0, len);

  char pb[CRSALib::MAX_UNIT_PRECISION*2], cb[CRSALib::MAX_UNIT_PRECISION*2];

  int res = 0, res1 = 0;
  do
  {
    memset(cb, 0, CRSALib::MAX_UNIT_PRECISION*2);
    memset(pb, 0, CRSALib::MAX_UNIT_PRECISION*2);

    memcpy(cb, c+stC, blocksize);

    if ((res = rsalib.mp_modexp((unsigned short*)pb, (unsigned short*)cb, (unsigned short *)d, (unsigned short *)n))!=0)
    {
         res1 = res;

    }


    memcpy(buf+stP, pb, workblocksize);

    stC += blocksize;
    stP += workblocksize;
    iLen -= blocksize;
  } while ((iLen > 0)&&(iLen >= blocksize));

  rcLen = *(unsigned short*)buf;

  if (len >= rcLen)
  {
    *dlen = rcLen;
    memcpy(dcrp, buf+sizeof(short), rcLen);
  }
  else
  {
    rcLen = 0;
  }
  free(buf);
  return rcLen;
}

unsigned int GetKeyBase(const unsigned short *n)
{
  if(!n) return 0;
  CRSALib rsalib(CRSALib::MAX_UNIT_PRECISION);
  rsalib.set_precision(CRSALib::MAX_UNIT_PRECISION);
  int blocksize = rsalib.significance((unsigned short *)n);
  return blocksize;
}

unsigned int GetKeyBaseB(const unsigned short *n)
{
  if(!n) return 0;
  CRSALib rsalib(CRSALib::MAX_UNIT_PRECISION);
  rsalib.set_precision(CRSALib::MAX_UNIT_PRECISION);
  int blocksize = rsalib.significance((unsigned short *)n);
  return blocksize * 2;
}
//---
