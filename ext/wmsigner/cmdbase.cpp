#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
//#include <io.h>
#include <string.h>
#include "ctype.h"
#include "cmdbase.h"

WORD SwitchIndian(WORD n1)
{
#ifndef LOWBYTEFIRST
  WORD n2;

  char* ps=(char*)&n1;
  char* pd=(char*)&n2;
  pd[1] = ps[0];
  pd[0] = ps[1];

  return n2;
#else
  return n1;
#endif
}

DWORD SwitchIndian(DWORD n1)
{
#ifndef LOWBYTEFIRST
  DWORD n2;

  char* ps=(char*)&n1;
  char* pd=(char*)&n2;
  pd[3] = ps[0];
  pd[2] = ps[1];
  pd[1] = ps[2];
  pd[0] = ps[3];

  return n2;
#else
  return n1;
#endif
}

szptr::szptr(const char *csz)
{
  if (csz)
  {
    sz = new char[::strlen(csz)+4];
    strcpy(sz, csz);
  }
  else
    sz = NULL;
}

szptr::szptr(const szptr& cszptr)
{
  if ((const char *)cszptr)
  {
    sz = new char[cszptr.strlen()+4];
    sz = strcpy(sz, cszptr);
  }
  else
    sz = (const char *)cszptr ? strcpy(new char[cszptr.strlen()+4], cszptr) : NULL;
}

szptr::~szptr()
{
  if(sz) delete[] sz;
}

char* szptr::operator = (char *csz)
{
  if(sz && csz)
  {
    if(!strcmp(csz,sz))
      return sz;
  }

  char *szprev = sz;
  if(csz)
  {
    sz = new char[::strlen(csz)+4];
    sz = strcpy(sz, csz);
  }
  else
    sz = NULL;

  if(szprev)
    delete[] szprev;

  return sz;
}

szptr& szptr::operator = (const szptr& cszptr)
{
  if(sz && cszptr.sz)
    if(!strcmp(cszptr,sz))
      return *this;

  char *szprev = sz;
  if(cszptr)
  {
    sz = new char[::strlen(cszptr)+4];
    sz = strcpy(sz, cszptr);
  }
  else
    sz = NULL;
  if(szprev)
    delete[] szprev;
  return *this;
}

szptr& szptr::operator += (const szptr& cszptr)
{
  if(!&cszptr) return *this;
  if(!cszptr.strlen()) return *this;

  char *szprev = sz;
  sz = new char[strlen()+cszptr.strlen()+4];
  if(szprev)
  {
    strcpy(sz, szprev);
    delete[] szprev;
  }
  else
    sz[0] = '\0';

  strcat(sz, cszptr);
  return *this;
}

szptr& szptr::TrimRight()
{
  if (NULL== this->sz)
    return *this;
  char* lpsz = this->sz;
  char* lpszLast = NULL;

  while (*lpsz != '\0')
  {
    if (*lpsz == ' ')
    {
      if (lpszLast == NULL)
        lpszLast = lpsz;
    }
    else
      lpszLast = NULL;
    lpsz = ((char*)lpsz)+1;
  }

  if (lpszLast != NULL)
  {
    *lpszLast = '\0';
  }
  return *this;
}

szptr& szptr::TrimLeft()
{
  if (NULL== this->sz)
    return *this;
  char* lpsz = this->sz;
  int nLen = (int)::strlen(sz);
  while ((*lpsz==' '))
    lpsz = ((char*)lpsz)+1;

  if (lpsz != sz)
  {
    int nDataLength = (int)nLen - (int)(lpsz - sz);
    memmove(sz, lpsz, (nDataLength+1)*sizeof(char));
  }
  return *this;
}

static char *dwordFromBuf(DWORD *wMember, char *szNextElemBufPtr)
{
  *wMember = SwitchIndian(*((DWORD*)szNextElemBufPtr));
  return (szNextElemBufPtr+sizeof(DWORD));
}

static char *wordFromBuf(WORD *wMember, char *szNextElemBufPtr)
{
  *wMember = SwitchIndian(*((WORD*)szNextElemBufPtr));
  return (szNextElemBufPtr+sizeof(WORD));
}

static char *dwordToBuf(char *szNextElemBufPtr, DWORD wMember)
{
  *((DWORD*)szNextElemBufPtr) = wMember;
  return (szNextElemBufPtr+sizeof(DWORD));
}

static char *wordToBuf(char *szNextElemBufPtr, WORD wMember)
{
  *((WORD*)szNextElemBufPtr) = wMember;
  return (szNextElemBufPtr+sizeof(WORD));
}


/**/
Keys::Keys()
  :dwReserv(0)
{
  memset(arwEKey, 0, (MAX_UNIT_PRECISION) * 2);
  memset(arwNKey, 0, (MAX_UNIT_PRECISION) * 2);
  wEKeyBase= wNKeyBase = 0;
}

Keys::Keys(const Keys& keysFrom)
{
  dwReserv = keysFrom.dwReserv;
  wEKeyBase= wNKeyBase = 0;
  memcpy(arwEKey, keysFrom.arwEKey, (MAX_UNIT_PRECISION) * 2);
  memcpy(arwNKey, keysFrom.arwEKey, (MAX_UNIT_PRECISION) * 2);
  wEKeyBase = keysFrom.wEKeyBase;
  wNKeyBase = keysFrom.wNKeyBase;
}

Keys& Keys::operator=(const Keys& keysFrom)
{
  dwReserv = keysFrom.dwReserv;
  memcpy(arwEKey, keysFrom.arwEKey, (MAX_UNIT_PRECISION) * 2);
  memcpy(arwNKey, keysFrom.arwNKey, (MAX_UNIT_PRECISION) * 2);
  wEKeyBase = keysFrom.wEKeyBase;
  wNKeyBase = keysFrom.wNKeyBase;
  return *this;
}

DWORD Keys::GetMembersSize()
{
  return (
      sizeof(dwReserv)
    + GetKeyBaseB(arwEKey)
    + GetKeyBaseB(arwNKey)
    + sizeof(wEKeyBase)
    + sizeof(wNKeyBase));
}

char *Keys::LoadMembers(char *BufPtr)
{
  char *ptrNextMemb = dwordFromBuf(&dwReserv, BufPtr);

  ptrNextMemb = wordFromBuf(&wEKeyBase, ptrNextMemb);
  memcpy(arwEKey, ptrNextMemb, wEKeyBase);
  for(WORD i=0;i<wEKeyBase/sizeof(arwEKey[0]);i++)
  { arwEKey[i] = SwitchIndian(arwEKey[i]); }

  ptrNextMemb += wEKeyBase;

  ptrNextMemb = wordFromBuf(&wNKeyBase, ptrNextMemb);
  memcpy(arwNKey, ptrNextMemb, wNKeyBase);
  for(unsigned int i=0;i<wNKeyBase/sizeof(arwNKey[0]);i++)
  { arwNKey[i] = SwitchIndian(arwNKey[i]); }

  ptrNextMemb += wNKeyBase;

  return ptrNextMemb;
}

char *Keys::SaveMembers(char *BufPtr)
{
  char *ptrNextMemb = dwordToBuf(BufPtr, dwReserv);

  wEKeyBase = GetKeyBaseB(arwEKey);
  ptrNextMemb = wordToBuf(ptrNextMemb, wEKeyBase);
  memcpy(ptrNextMemb, arwEKey, wEKeyBase);
  ptrNextMemb += wEKeyBase;

  wNKeyBase = GetKeyBaseB(arwNKey);
  ptrNextMemb = wordToBuf(ptrNextMemb, wNKeyBase);
  memcpy(ptrNextMemb, arwNKey, wNKeyBase);
  ptrNextMemb += wNKeyBase;

  return ptrNextMemb;
}


void Keys::RecalcBase()
{
  wEKeyBase = GetKeyBaseB(arwEKey);
  wNKeyBase = GetKeyBaseB(arwNKey);
}

int Keys::LoadFromBuffer(const char *Buf, DWORD dwBufLen)
{
  if(dwBufLen < KeyFileFormat::sizeof_header)
    return _CMDLOAD_ERR_BUF_LEN_;

  KeyFileFormat *keyFmt = (KeyFileFormat *)Buf;
  DWORD ardwRecievedCRC[4], ardwCheckedCRC[4], i;

  if(dwBufLen-2*sizeof(DWORD) >= SwitchIndian(keyFmt->dwLenBuf))
  {
    for(i=0; i<4; i++)
      ardwRecievedCRC[i] = SwitchIndian(keyFmt->dwCRC[i]);
    for(i=0; i<4; i++)  keyFmt->dwCRC[i] = 0;
    CountCrcMD4(ardwCheckedCRC, Buf, SwitchIndian(keyFmt->dwLenBuf)+KeyFileFormat::sizeof_header);

    for(i=0; i<4; i++)  keyFmt->dwCRC[i] = SwitchIndian(ardwRecievedCRC[i]);

    bool bCrcGood = true;
    for(i=0; i<4; i++)
      if(ardwCheckedCRC[i]!=ardwRecievedCRC[i])
      {
        bCrcGood = false;
        break;
      }

    if(bCrcGood)
    {
      LoadMembers(keyFmt->ptrBuffer);
      return 0;
    }
    else
      return _CMDLOAD_ERR_CMD_CRC_;
  }
  else
    return _CMDLOAD_ERR_BUF_LEN_;
}

int Keys::SaveIntoBuffer(char **ptrAllocBuf, DWORD *dwBufLen)
{
  char *Buf;
  KeyFileFormat *cmdFmt;
  DWORD dwMembersSize;
  DWORD dwBufSize, i;
  BOOL bRC = false;

  dwMembersSize = GetMembersSize();

  dwBufSize = dwMembersSize+KeyFileFormat::sizeof_header;
  Buf = new char[dwBufSize];
  memset(Buf, 0, dwBufSize);  // Clear for Trail...
  cmdFmt = (KeyFileFormat *)Buf;
  if(Buf)
  {
    char *BufMemb;
    BufMemb = cmdFmt->ptrBuffer;

    if(SaveMembers(BufMemb))
    {
      cmdFmt->wReserved1 = 0x81;
      cmdFmt->wSignFlag = 0;
      cmdFmt->dwLenBuf = dwMembersSize;

      for(i=0; i<4; i++)  cmdFmt->dwCRC[i] = 0;
      CountCrcMD4(cmdFmt->dwCRC, Buf, dwBufSize); //*((WORD *)(Buf+sizeof(WORD)))=
      *dwBufLen = dwBufSize;
      *ptrAllocBuf = Buf;
      bRC = true;
    }
  }
  else
    bRC = false;   // NOT_ENOUGH_MEMORY

  return bRC;
}

 bool Keys::CountCrcMD4(DWORD *dwCRC, const char *Buf, DWORD dwBufLenBytes)
{
  int b,bitcount;
  MDstruct MD;

  MDbegin(&MD);
  for(b=0,bitcount=512; (unsigned int)b<dwBufLenBytes/64+1; b++)
  {
    if((unsigned int)b==dwBufLenBytes/64) bitcount = (dwBufLenBytes%64)<<3;
    MDupdate(&MD, (unsigned char *)(Buf+b*64), bitcount);
  }
  MDupdate(&MD, (unsigned char *)Buf, 0);

  for(b=0; b<4; b++) dwCRC[b] = MD.buffer[b];

  return true;
}

bool us2sz(const unsigned short *buf, int len, char *szBuffer)
{
  char tmp[5];
  szBuffer[0] = '\0';

  for(int i=0;i<len;i++)
  {
    sprintf(tmp, "%04x", buf[i]);
    strcat(szBuffer, tmp);
  }
  return true;
}

char stohb(char s)
{
  if ( s>='0' && s<='9') return (s-'0');
  else
    if ( s>='A' && s<='F') return (s-'A'+0xA);
    else
      if ( s>='a' && s<='f') return (s-'a'+0xA);
  return 0;
}

bool sz2us(const char *szBuffer, unsigned short *usBuf)
{
  const char* p = szBuffer;
  int l = (int)strlen(szBuffer);
  unsigned short cell = 0;
  for(int i=0,k=0; i<l; i+=4) {
    cell = 0;
    cell = stohb(*p++);
    cell <<= 4;
    cell |= stohb(*p++);
    cell <<= 4;
    cell |= stohb(*p++);
    cell <<= 4;
    cell |= stohb(*p++);
    usBuf[k++] = cell;
  }
  return true;
}
//----
