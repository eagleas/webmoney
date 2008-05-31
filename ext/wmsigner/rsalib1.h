#ifndef __RSALIB1_H_INCLUDE__
#define __RSALIB1_H_INCLUDE__
#include "stdafx.h"

typedef unsigned char boolean;
typedef unsigned char byte;
typedef unsigned short word16;
typedef word16 unit;
typedef unit *unitptr;
typedef short signedunit;
typedef unsigned long int ulint;

class CRSALib
{
public:

  enum { MAX_BIT_PRECISION = 2048, MAX_UNIT_PRECISION = MAX_BIT_PRECISION/(sizeof(word16)*8) };
private:
  unit moduli_buf[16][(MAX_UNIT_PRECISION)];
  unitptr moduli[16+1];

  unit msu_moduli[16+1];
  unit nmsu_moduli[16+1];
  unit mpdbuf[16-1][(MAX_UNIT_PRECISION)];
  unitptr mpd[16];

public:
  short global_precision;
  void set_precision(short prec);
  CRSALib(short glob_pres=0);

  boolean mp_addc(register unitptr r1,register unitptr r2,register boolean carry);

  boolean mp_subb(register unitptr r1,register unitptr r2,register boolean borrow);
  boolean mp_rotate_left(register unitptr r1,register boolean carry);
  boolean mp_rotate_right(register unitptr r1,register boolean carry);
  short mp_compare(register unitptr r1,register unitptr r2);
  boolean mp_inc(register unitptr r);
  boolean mp_dec(register unitptr r);
  void mp_neg(register unitptr r);
  void mp_move(register unitptr dst,register unitptr src);
  void mp_init(register unitptr r, word16 value);
  short significance(register unitptr r);
  void unitfill0(unitptr r,word16 unitcount);
  int mp_udiv(register unitptr remainder,register unitptr quotient,
    register unitptr dividend,register unitptr divisor);
  int mp_div(register unitptr remainder,register unitptr quotient,
    register unitptr dividend,register unitptr divisor);
  word16 mp_shortdiv(register unitptr quotient,
    register unitptr dividend,register word16 divisor);
  int mp_mod(register unitptr remainder,
    register unitptr dividend,register unitptr divisor);
  word16 mp_shortmod(register unitptr dividend,register word16 divisor);
  int mp_mult(register unitptr prod,
    register unitptr multiplicand,register unitptr multiplier);

private:
  void mp_lshift_unit(register unitptr r1);
  void stage_mp_images(unitptr images[16],unitptr r);

public:
  int stage_merritt_modulus(unitptr n);
  int merritt_modmult(register unitptr prod,
    unitptr multiplicand,register unitptr multiplier);

private:
  void merritt_burn(void);

public:
  int countbits(unitptr r);

  int mp_modexp(register unitptr expout,register unitptr expin,
  register unitptr exponent,register unitptr modulus);

  int rsa_decrypt(unitptr M, unitptr C,	unitptr d, unitptr p, unitptr q, unitptr u);
  int mp_sqrt(unitptr quotient,unitptr dividend);
};

inline void CRSALib::set_precision(short prec) {global_precision = prec;}
#endif
//---
