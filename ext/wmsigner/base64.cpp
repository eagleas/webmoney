/****************************************************************************************************************************
 *  Usage this module :
 *  size_t result = code64( JOB [ENCODE or DECODE], char *ASCII_Buffer, size_t ASCII_BUFFER_SIZE, 
 *                          char *BASE64_Buffer,  size_t BASE64_BUFFER_SIZE );
 *  Sample for decode from ascii to base64 : 
 *  result = code64( DECODE, char *ASCII_Buffer, size_t ASCII_BUFFER_SIZE, char *BASE64_Buffer,  size_t BASE64_BUFFER_SIZE );
 *  Parameter ASCII_BUFFER_SIZE - definition size input to decode sequence ! 
 *  function strlen() - may be used ONLY for text buffers, otherwize - BINARY DATA, use really size !
 *  Sample for encode from base64 to ascii : 
 *  result = code64( ENCODE, char *ASCII_Buffer, size_t ASCII_BUFFER_SIZE, char *BASE64_Buffer,  size_t BASE64_BUFFER_SIZE );
 *  Parameter BASE64_BUFFER_SIZE - definition size input to encode sequence !
 *  function strlen() may be used for counting size for BASE64 array, if last symbol == '\0', otherwise use really size !
 *  .........................................................................................................................
 *  Return value:
 *  size_t result - counter, number of bytes in OUTPUT array, whose successfully encoded/decoded.
 *  if result == 0 - error found, abnormal terminating, nothing to encoding or decoding.
 *  .........................................................................................................................
 *  Internal function: idx64( char Ch ); Binary search index in Base64 array, for Ch character in parameter
 *  .........................................................................................................................
 *  This module present "AS IS", absolutely no warranty, if anybody modyfied this source.
 ****************************************************************************************************************************/
#include "base64.h"

/* Base_64 characters  */
const char Ch64[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/*  Presort array for indexes  */
const INDEX64 Id64[64] = {
  {'+',62},{'/',63},{'0',52},{'1',53},{'2',54},{'3',55},{'4',56},{'5',57},{'6',58},{'7',59},{'8',60},{'9',61},
  {'A',0},{'B',1},{'C',2},{'D',3},{'E',4},{'F',5},{'G',6},{'H',7},{'I',8},{'J',9},{'K',10},{'L',11},{'M',12},
  {'N',13},{'O',14},{'P',15},{'Q',16},{'R',17},{'S',18},{'T',19},{'U',20},{'V',21},{'W',22},{'X',23},{'Y',24},{'Z',25},
  {'a',26},{'b',27},{'c',28},{'d',29},{'e',30},{'f',31},{'g',32},{'h',33},{'i',34},{'j',35},{'k',36},{'l',37},{'m',38},
  {'n',39},{'o',40},{'p',41},{'q',42},{'r',43},{'s',44},{'t',45},{'u',46},{'v',47},{'w',48},{'x',49},{'y',50},{'z',51}
};
  
/*  Base64 ENCODE / DECODE function  */
size_t code64( int job, char *buf_ascii, size_t ascii_size, char *buf_64, size_t buf_64_size ) 
{
  BASE64 b64;
  size_t i = 0, j = 0, k = 0, i3 = 0; /*  job indexes */
  size_t ask_len = 0;   /* Internal variable for size ascii buffer   */
  size_t buf64_len = 0; /* Internal variable for size base64 buffer  */

  b64.a[0] = 0; b64.a[1] = 0; b64.a[2] = 0;

/*  Decoding to Base64 code  */
  if( job == DECODE ) {
    ask_len = ascii_size;
    if( (ascii_size * 4 / 3) > buf_64_size ) return( CODE_ERR ); /* No enough space to decoding */
    if( ask_len == 0 ) return( CODE_ERR );
    i3 = (int) 3 * (ask_len / 3);      /* Dividing by 3       */
    if( i3 > 0 ) k = 3 - ask_len + i3; /* End of seq (1 or 2) */
    if( ask_len < 3 ) k = 3 - ask_len;

    while( i < i3 ) {
      b64.a[2] = buf_ascii[i];
      b64.a[1] = buf_ascii[i+1];
      b64.a[0] = buf_ascii[i+2];
      buf_64[j++] = Ch64[b64.b.b0];
      buf_64[j++] = Ch64[b64.b.b1];
      buf_64[j++] = Ch64[b64.b.b2];
      buf_64[j++] = Ch64[b64.b.b3];
      i+=3;
    }

    if( k == 2 ) {
      b64.a[2] = buf_ascii[i];
      b64.a[1] = 0;
      b64.a[0] = 0;
      buf_64[j++] = Ch64[b64.b.b0];
      buf_64[j++] = Ch64[b64.b.b1];
      buf_64[j++] = '=';
      buf_64[j++] = '=';
    }

    if( k == 1 ) {
      b64.a[2] = buf_ascii[i];
      b64.a[1] = buf_ascii[i+1];
      b64.a[0] = 0;
      buf_64[j++] = Ch64[b64.b.b0];
      buf_64[j++] = Ch64[b64.b.b1];
      buf_64[j++] = Ch64[b64.b.b2];
      buf_64[j++] = '=';
    }

    return( j );
  }

/* Restoring original characters */
  if( job == ENCODE ) {
    buf64_len = buf_64_size;
    if( buf64_len < 4 ) return( CODE_ERR ); /* Too small input buffer  */
    if( (buf_64_size * 3 / 4) > ascii_size ) return( CODE_ERR ); /* No enough space to encoding */
    i3 = buf64_len / 4;
    k = buf64_len - i3 * 4;
    if( k ) return( CODE_ERR ); /*  Illegal size for input sequence !! */
    k = 0;                      /*  Counter original bytes for output  */

    for( i = 0; i < buf64_len; i+=4 ) {
      b64.b.b0 = idx64( buf_64[i] );
      b64.b.b1 = idx64( buf_64[i+1] );
      b64.b.b2 = 0; b64.b.b3 = 0;
      if( buf_64[i+2] != '=' ) b64.b.b2 = idx64( buf_64[i+2] );
      else k--;
      if( buf_64[i+3] != '=' ) b64.b.b3 = idx64( buf_64[i+3] );
      else k--;
      buf_ascii[j++] = b64.a[2]; k++;
      buf_ascii[j++] = b64.a[1]; k++;
      buf_ascii[j++] = b64.a[0]; k++;
    }

    return( k );
  }

  return( CODE_ERR ); /*  Unknown command ! */
}

/*  Binary search character's index in array  */
int idx64( char ch )
{
  int start = 0;
  int pos   = 32;
  int end   = 63;

  while( (pos >= start) || (pos <= end) ) {
     if( ch == Id64[start].Ch ) return( Id64[start].Id );
     if( ch == Id64[pos].Ch )   return( Id64[pos].Id );
     if( ch == Id64[end].Ch )   return( Id64[end].Id );

     if( ch > Id64[pos].Ch ) {
        start = pos;
     }

     if( ch < Id64[pos].Ch ) {
        end = pos;
     }

     pos = (int) (start+end) / 2;
  }

/*  Illegal character found, task aborted !  */
  fprintf( stderr, "\n\rBase64 Fatal Error: Illegal character found : '%c' [%d] - No Base64 legal character!!\n\r", ch, ch );
  exit(1);
}
