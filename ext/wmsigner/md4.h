#ifndef _INCLUDE_MD4
#define _INCLUDE_MD4
#include "stdafx.h"

#ifndef _WIN32
#define _NOT_WIN32
#endif

#if defined(__FreeBSD__) && __FreeBSD__ < 5 	/* for FreeBSD version <= 4 */
#include <inttypes.h> 
#elif defined(_NOT_WIN32)
#include <stdint.h>
#endif

#ifdef _WIN32
typedef DWORD Word32Type;
#else
typedef uint32_t Word32Type;
#endif

typedef struct {
  Word32Type buffer[4];
  unsigned char count[8];
  unsigned int done;
} MDstruct, *MDptr;

#ifdef __cplusplus
extern "C" {
#endif
extern void MDbegin(MDptr MDp) ;

extern void MDupdate(MDptr MDp, unsigned char *X, Word32Type count) ;

extern void MDprint(MDptr MDp) ;

#ifdef __cplusplus
}
#endif

#endif
//---
