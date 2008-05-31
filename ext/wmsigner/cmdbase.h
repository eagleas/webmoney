#ifndef __CMDBASE_INCLUDE__
#define __CMDBASE_INCLUDE__
#include "stdafx.h"
#include "crypto.h"
#include "md4.h"
#include <stdio.h>
#include "string.h"
//--------------------

#ifndef _WIN32
#define _NOT_WIN32
#endif

#if defined(__FreeBSD__) && __FreeBSD__ < 5     /* for FreeBSD version <= 4 */
#include <inttypes.h> 
#elif defined(_NOT_WIN32)
#include <stdint.h>
#endif

#ifndef _WIN32
typedef uint32_t DWORD;
typedef bool BOOL;
typedef uint8_t BYTE;
typedef uint16_t WORD;
#endif


//--------------------
#define LOWBYTEFIRST
#define EBITS     (48)
#define KEYBITS   (528)

#define MAX_BIT_PRECISION (2048)
#define MAX_UNIT_PRECISION (MAX_BIT_PRECISION/(sizeof(unsigned short)*8))

#define _CMDLOAD_ERR_CMD_CRIPTION_  1
#define _CMDLOAD_ERR_CMD_CRC_       2
#define _CMDLOAD_ERR_BUF_LEN_       3
#define _CMDLOAD_ERR_CMD_DECODE_    4
#define _CMDLOAD_ERR_CMD_CODE_      5
#define _CMDLOAD_ERR_NULL_KEY_      6

class szptr
{
  char *sz;

public:
  szptr() { sz = NULL; }
  szptr(const char *csz);
  szptr(const szptr& cszptr);
  ~szptr();

  char* operator = (char *csz);
  szptr& operator = (const szptr& cszptr);
  szptr& operator += (const szptr& cszptr);
  inline void ReplaceIncluding(char *szp) { if(sz) delete sz; sz = szp; }
  inline char operator*() { return sz ? *sz : '\0'; }
  inline char operator[](int i) const { return sz ? *(sz+i) : '\0'; }
  inline operator char const * const () const { return sz; }
  int strlen() const {
    if (sz) return (int)::strlen(sz);
    else return 0;
  }
  inline bool operator==(const szptr& s) const { return (sz && s.sz) ? (strcmp(s.sz,sz)==0) : (sz == s.sz); }
  inline bool operator!=(const szptr& s) const { return (sz && s.sz) ? (strcmp(s.sz,sz)!=0) : (sz != s.sz); }

  szptr& TrimLeft();
  szptr& TrimRight();
};


WORD SwitchIndian(WORD n1);
DWORD SwitchIndian(DWORD n1);

struct KeyFileFormat
{
  enum {sizeof_header = sizeof(WORD)*2 + sizeof(DWORD)*5, sizeof_crc = (sizeof(DWORD)*4)};
  WORD  wReserved1;
  WORD  wSignFlag;
  DWORD dwCRC[4];
  DWORD dwLenBuf;
  char  ptrBuffer[1];
};

struct Keys
{
  DWORD dwReserv;
  WORD arwEKey[MAX_UNIT_PRECISION];
  WORD arwNKey[MAX_UNIT_PRECISION];
  WORD wEKeyBase;
  WORD wNKeyBase;

  Keys();
  Keys(const Keys& keysFrom);
  Keys& operator=(const Keys& KeysFrom);
  virtual DWORD GetMembersSize();
  virtual char*  LoadMembers(char *BufPtr);
  virtual int LoadFromBuffer(const char *Buf, DWORD dwBufLen);
  virtual char*  SaveMembers(char *BufPtr);
  virtual int SaveIntoBuffer(char **ptrAllocBuf, DWORD *dwBufLen);

  static bool CountCrcMD4(DWORD *dwCRC, const char *Buf, DWORD dwBufLenBytes);
  void RecalcBase();
};


bool us2sz(const unsigned short *buf, int len, char *szBuffer);
char stohb(char s);
bool sz2us(const char *szBuffer, unsigned short *usBuf);
#endif
//---
