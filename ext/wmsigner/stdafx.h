// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

// REMOVE COMMENT FOR DEBUG MODE 
//#ifndef _DEBUG
//#define _DEBUG
//#endif


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <errno.h>
#ifdef _WIN32
#pragma once
#include <iostream>
#include <tchar.h>
#include <windows.h>
#include <io.h>
#include <memory.h>
#pragma warning(disable : 4996)
#endif
// TODO: reference additional headers your program requires here
#ifndef TRUE
#define TRUE	1
#endif
#ifndef FALSE
#define FALSE	0
#endif

