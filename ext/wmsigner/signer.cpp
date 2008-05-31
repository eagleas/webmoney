#include "stdafx.h"
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <time.h>
#include "signer.h"

#ifdef _WIN32
#include <io.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#define __open _open
#define __read _read
#define __close _close
#else
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/uio.h>
#include <unistd.h>
#include <errno.h>
#define __open	open
#define __read	read
#define __close	close
#endif

#ifndef TRUE
#define TRUE	1
#endif
#ifndef FALSE
#define FALSE	0
#endif

bool Signer::SecureKeyByIDPW(char *buf, DWORD dwBuf)
{
  if(((KeyFileFormat *)buf)->wSignFlag == 0)
  {
    m_siErrorCode = -2;
    return false;
  };
  DWORD dwCRC[4];
  szptr szIDPW = m_szUserName;
  szIDPW += m_szPassword;
  Keys::CountCrcMD4(dwCRC, szIDPW, szIDPW.strlen());

  dwCRC[0] = SwitchIndian(dwCRC[0]);
  dwCRC[1] = SwitchIndian(dwCRC[1]);
  dwCRC[2] = SwitchIndian(dwCRC[2]);
  dwCRC[3] = SwitchIndian(dwCRC[3]);

  char *ptrKey = ((KeyFileFormat *)buf)->ptrBuffer;
  DWORD dwKeyLen = dwBuf-(ptrKey-buf) - 6;
  ptrKey += 6;
  for(DWORD dwProc=0; dwProc<dwKeyLen; dwProc+=sizeof(dwCRC))
    for(int k=0; k<sizeof(dwCRC)&&(dwProc+k)<dwKeyLen; k++)
      *(ptrKey+dwProc+k) ^= ((char *)dwCRC)[k];
  return true;
}


bool Signer::SecureKeyByIDPWHalf(char *buf, DWORD dwBuf)
{
  if(((KeyFileFormat *)buf)->wSignFlag == 0)
  {
    m_siErrorCode = -2;
    return false;
  };
  DWORD dwCRC[4];
  szptr szIDPW = m_szUserName;
  int len = (int) strlen(m_szPassword)/2 + 1;
  if (len > 1)
  {
    char* pBuf = new char[len];
    strncpy(pBuf, m_szPassword, len-1);
    pBuf[len-1] = '\0';
    szIDPW += pBuf;
    
    delete [] pBuf;
  }
  Keys::CountCrcMD4(dwCRC, szIDPW, szIDPW.strlen());

  dwCRC[0] = SwitchIndian(dwCRC[0]);
  dwCRC[1] = SwitchIndian(dwCRC[1]);
  dwCRC[2] = SwitchIndian(dwCRC[2]);
  dwCRC[3] = SwitchIndian(dwCRC[3]);

  char *ptrKey = ((KeyFileFormat *)buf)->ptrBuffer;
  DWORD dwKeyLen = dwBuf-(ptrKey-buf) - 6;
  ptrKey += 6;
  for(DWORD dwProc=0; dwProc<dwKeyLen; dwProc+=sizeof(dwCRC))
    for(int k=0; k<sizeof(dwCRC)&&(dwProc+k)<dwKeyLen; k++)
      *(ptrKey+dwProc+k) ^= ((char *)dwCRC)[k];
  return true;
}
//---------------------------------------------------------
void Signer::SetKeyFromCL( int flag, char *KeyBuf )
{
   KeyFromCL = FALSE;
   if( flag == TRUE ) KeyFromCL = TRUE;
   memcpy( (void *) szKeyData, (const void *)KeyBuf, 164 );
}
//---------------------------------------------------------

int Signer::LoadKeys()
{
  bool bKeysReaded = false, bNotOldFmt = false;
  int nReaden;
  int errLoadKey;
  int fh = -1;
  int st_size = 0;
  const int nMaxBufLen = sizeof(Keys) + KeyFileFormat::sizeof_header;
  char *pBufRead = new char[nMaxBufLen];   // Here Keys must be
  m_siErrorCode = 0;
  KeyFromCL = FALSE;

if( (!isIgnoreKeyFile) && (Key64Flag == FALSE) ) {
  #ifdef O_BINARY
  fh = __open( m_szKeyFileName, O_RDONLY | O_BINARY);
  #else
  fh = __open( m_szKeyFileName, O_RDONLY);
  #endif

  if( fh == -1 )
  {
    m_siErrorCode = errno;
    return false;
  }

  st_size = lseek(fh, 0, SEEK_END);
  lseek(fh, 0, SEEK_SET);
  if (st_size == lMinKeyFileSize)
  {
    // load 164 bytes from "small" keys file
    nReaden = __read( fh, pBufRead, nMaxBufLen );
    bKeysReaded = (nReaden == lMinKeyFileSize);
  }
  __close( fh );
} 
else {
   bKeysReaded = true;
   nReaden = lMinKeyFileSize;
   memcpy( pBufRead, szKeyData, lMinKeyFileSize);
}

  //*************************************************************************

  if(bKeysReaded)
  {
    SecureKeyByIDPWHalf(pBufRead, lMinKeyFileSize);
    WORD old_SignFlag;
    old_SignFlag = ((KeyFileFormat *)pBufRead)->wSignFlag;
    ((KeyFileFormat *)pBufRead)->wSignFlag = 0;
    errLoadKey = keys.LoadFromBuffer( pBufRead, lMinKeyFileSize );
    if(errLoadKey)
    {
      // Restore for correct Loading (CRC) !
      ((KeyFileFormat *)pBufRead)->wSignFlag = old_SignFlag;
      SecureKeyByIDPWHalf(pBufRead, lMinKeyFileSize); // restore buffer

      SecureKeyByIDPW(pBufRead, lMinKeyFileSize);

      ((KeyFileFormat *)pBufRead)->wSignFlag = 0;
      errLoadKey = keys.LoadFromBuffer( pBufRead, lMinKeyFileSize );
    }

    delete[] pBufRead;
    if( !errLoadKey )
      bKeysReaded = true;
    else
    {
      Keys flushKey;
      keys = flushKey;
      m_siErrorCode = -3;
    }
  }

  return bKeysReaded;
}

Signer::Signer(const char * szLogin, const char *szPassword, const char *szKeyFileName)
 : m_szUserName(szLogin), m_szPassword(szPassword), m_szKeyFileName(szKeyFileName)
{
  m_siErrorCode = 0;
  isIgnoreKeyFile = false;
  isIgnoreIniFile = false;
  isKWMFileFromCL = false;
  memset(szKeyData, 0, MAXBUF+1);
  Key64Flag = FALSE;
}

short Signer::ErrorCode()
{
  return m_siErrorCode;
}

bool Signer::Sign(const char *szIn, szptr& szSign)
{
  DWORD dwCRC[14];
#ifdef _DEBUG
	printf("\n\rSign - Start !");
#endif

  if (!LoadKeys())
  {
    puts("!LoadKeys");
    return false;
  }
#ifdef _DEBUG
	printf("\n\rSign - Load Keys");
#endif

  if(!keys.wEKeyBase || !keys.wNKeyBase)
    return false;

#ifdef _DEBUG
  char *szInHex = new char [(strlen(szIn)+1)*2+1];
  us2sz((const unsigned short *)szIn, (int)(strlen(szIn)+1)/2, szInHex);
  puts("\n\rInput:\n");
  puts(szIn);
  puts("\nin hex:\n");
  puts(szInHex);
  puts("\n");
  delete [] szInHex;
#endif

  if(Keys::CountCrcMD4(dwCRC, szIn, (DWORD)strlen(szIn)))
  {
    DWORD dwCrpSize = GetCLenB(sizeof(dwCRC), keys.arwNKey);
    char *ptrCrpBlock = new char[dwCrpSize];
#ifdef _DEBUG
    for(int i=4; i<14; i++) dwCRC[i] = 0;
#else
    srand((unsigned)time(NULL));
  for(int i=4; i<14; i++) dwCRC[i] = rand();
#endif
    dwCRC[0] = SwitchIndian(dwCRC[0]);
    dwCRC[1] = SwitchIndian(dwCRC[1]);
    dwCRC[2] = SwitchIndian(dwCRC[2]);
    dwCRC[3] = SwitchIndian(dwCRC[3]);
#ifdef _DEBUG
    for(int h=0;h<sizeof(dwCRC);h++)
    { printf("packing%d: %x\n", h, ((char*)dwCRC)[h]); }
#endif
#ifdef _DEBUG
	printf("\n\rCalling CrpB() - start");
#endif
    CrpB(ptrCrpBlock, (char *)dwCRC, sizeof(dwCRC), keys.arwEKey, keys.arwNKey);
#ifdef _DEBUG
	printf("\n\rCalling CrpB() - end");
#endif
    char *charCrpBlock = new char[dwCrpSize*2+1];
    us2sz((const unsigned short *)ptrCrpBlock, dwCrpSize/2, charCrpBlock);
    szSign = charCrpBlock;
#ifdef _DEBUG
	printf("\n\rSign - prepare end");
#endif
    
    delete [] charCrpBlock;
    delete [] ptrCrpBlock;

#ifdef _DEBUG
	printf("\n\rSign - end return true");
#endif
    
    return true;
  }

#ifdef _DEBUG
	printf("\n\rSign - end return false");
#endif
  return false;
}

Signer2::Signer2(const char *szLogin, const char *szPassword, const char *szKeyData)
  :Signer(szLogin, szPassword, ""), m_strKeyData(szKeyData)
{
  m_siErrorCode = 0;
}

int Signer2::LoadKeys()
{
  bool bKeysReaded = false, bNotOldFmt = false;
  int errLoadKey;

  int nStrKeyDataLen = m_strKeyData.strlen();
  const int nMaxBufLen = sizeof(Keys) + KeyFileFormat::sizeof_header;
  if ((nStrKeyDataLen>0) && (nStrKeyDataLen < nMaxBufLen*2))
  {
    BYTE *bKeyData = new BYTE[nMaxBufLen];
    sz2us(m_strKeyData, (unsigned short*)bKeyData);
    SecureKeyByIDPW((char*)bKeyData, nStrKeyDataLen / 2);
    ((KeyFileFormat *)bKeyData)->wSignFlag = 0;
    errLoadKey = keys.LoadFromBuffer((char*)bKeyData, nStrKeyDataLen / 2);
    delete bKeyData;
    if( !errLoadKey )
      bKeysReaded = true;
    else {
      Keys flushKey;
      keys = flushKey;
    m_siErrorCode = -2;
    }
  }
  else
  {
    errLoadKey = -1;
  m_siErrorCode = -1;
  }
  return (bKeysReaded);
}

short Signer2::ErrorCode()
{
  return m_siErrorCode;
}
//----
