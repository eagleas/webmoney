#include "stdafx.h"
#ifdef _WIN32
#ifndef _CONSOLE
#endif
#endif

#include "rsalib1.h"
#include <stdio.h>

int N_NEG_VAL=-1;

CRSALib::CRSALib(short glob_pres)
{
  global_precision = glob_pres;
  int i, j;
  for (i=0; i< 16; i++)
    for (j=0; j< MAX_UNIT_PRECISION; j++)
      moduli_buf[i][j]=0;
  moduli[0] = 0;
  for (i=1; i<16+1; i++)
    moduli[i] = &moduli_buf[ i-1][0];
  for (i=0;i<16+1;i++)
  {
    msu_moduli[i] = 0;
    nmsu_moduli[i] = 0;
  }
  for (i=0; i< 16-1; i++)
    for (j=0; j< MAX_UNIT_PRECISION; j++)
      mpdbuf[i][j]=0;

  mpd[0] = 0;
  for (i=1; i < 16; i++)
  {
    mpd[i] = &mpdbuf[ i-1][0];
  }
}

boolean CRSALib::mp_addc(register unitptr r1,register unitptr r2,register boolean carry)
{
  register ulint x;
  short precision;
  precision = global_precision;

  while (precision--)
  {
    x = (ulint) *r1 + (ulint) *((r2)++) + (ulint) carry;
    *((r1)++) = (unit)x;
    carry = ((x & ((ulint) 1 << 16)) != 0L);
  }
  return(carry);
}

boolean CRSALib::mp_subb(register unitptr r1,register unitptr r2,register boolean borrow)
{
  register ulint x;
  short precision;
  precision = global_precision;

  while (precision--)
  {
    x = (ulint) *r1 - (ulint) *((r2)++) - (ulint) borrow;
    *((r1)++) = (unit)x;
    borrow = ((x & ((ulint) 1 << 16)) != 0L);
  }
  return(borrow);
}

boolean CRSALib::mp_rotate_left(register unitptr r1,register boolean carry)
{
  register short precision;
  register boolean nextcarry;
  precision = global_precision;

  while (precision--)
  {
    nextcarry = (((signedunit) *r1) < 0);

    *r1 <<= 1 ;
    if (carry) *r1 |= 1;
    carry = nextcarry;
    (++(r1));
  }
  return(nextcarry);
}

boolean CRSALib::mp_rotate_right(register unitptr r1,register boolean carry)
{
  register short precision;
  register boolean nextcarry;
  precision = global_precision;
  (r1) = ((r1)+(precision)-1);
  while (precision--)
  {
    nextcarry = *r1 & 1;
    *r1 >>= 1 ;
    if (carry) *r1 |= ((unit) 0x8000);
    carry = nextcarry;
    (--(r1));
  }
  return(nextcarry);
}

short CRSALib::mp_compare(register unitptr r1,register unitptr r2)
{
  register short precision;
  precision = global_precision;
  (r1) = ((r1)+(precision)-1);
  (r2) = ((r2)+(precision)-1);
  do
  {
    if (*r1 < *r2)
      return(-1);
    if (*((r1)--) > *((r2)--))
      return(1);
  } while (--precision);
  return(0);
}

boolean CRSALib::mp_inc(register unitptr r)
{
  register short precision;
  precision = global_precision;

  do
  { if ( ++(*r) ) return(0);
    ((r)++);
  } while (--precision);
  return(1);
}

boolean CRSALib::mp_dec(register unitptr r)
{
  register short precision;
  precision = global_precision;

  do
  {
    if ( (signedunit) (--(*r)) != (signedunit) -1 )
      return(0);
    ((r)++);
  } while (--precision);
  return(1);
}

void CRSALib::mp_neg(register unitptr r)
{
  register short precision;
  precision = global_precision;

  mp_dec(r);
  do
  {
    *r = ~(*r);
    r++;
  } while (--precision);
}

void CRSALib::mp_move(register unitptr dst,register unitptr src)
{
  register short precision;
  precision = global_precision;
  do
  {
    *dst++ = *src++;
  } while (--precision);
}

void CRSALib::mp_init(register unitptr r, word16 value)
{
  register short precision;
  precision = global_precision;
  *((r)++) = value;
  precision--;
  while (precision--)
    *((r)++) = 0;
}

short CRSALib::significance(register unitptr r)
{
  register short precision;
  precision = global_precision;
  (r) = ((r)+(precision)-1);
  do
  {
    if (*((r)--))
      return(precision);
  } while (--precision);
  return(precision);
}

void CRSALib::unitfill0(unitptr r,word16 unitcount)
{
  while (unitcount--) *r++ = 0;
}

int CRSALib::mp_udiv(register unitptr remainder,register unitptr quotient,
  register unitptr dividend,register unitptr divisor)
{
  int bits;
  short dprec;
  register unit bitmask;
  if (( ((*(divisor))==(0)) && (significance(divisor)<=1) ))
    return(-1);

  mp_init(remainder,0);
  mp_init(quotient,0);

  {
    dprec = significance(dividend);
    if (!dprec) return(0);
    bits = ((dprec) << 4);
    (dividend) = ((dividend)+(dprec)-1);
    bitmask = ((unit) 0x8000);
    while (!(*(dividend) & bitmask))
    {
      bitmask >>= 1;
      bits--;
    }
  };

  (quotient) = ((quotient)+(dprec)-1);

  while (bits--)
  {
    mp_rotate_left(remainder,(boolean)((*(dividend) & bitmask)!=0));
    if (mp_compare(remainder,divisor) >= 0)
    {
      mp_subb(remainder,divisor,(boolean)0);
      *(quotient) |= bitmask;
    }
    {
      if (!(bitmask >>= 1))
      {
        bitmask = ((unit) 0x8000);
        ((dividend)--); ((quotient)--);
      }
    };
  }
  return(0);
}


int CRSALib::mp_div(register unitptr remainder,register unitptr quotient,
  register unitptr dividend,register unitptr divisor)
{
  boolean dvdsign,dsign;
  int status;
  dvdsign = (((signedunit) (*((dividend)+(global_precision)-1)) < 0)!=0);
  dsign = (((signedunit) (*((divisor)+(global_precision)-1)) < 0)!=0);
  if (dvdsign) mp_neg(dividend);
  if (dsign) mp_neg(divisor);
  status = mp_udiv(remainder,quotient,dividend,divisor);
  if (dvdsign) mp_neg(dividend);
  if (dsign) mp_neg(divisor);
  if (status<0) return(status);
  if (dvdsign) mp_neg(remainder);
  if (dvdsign ^ dsign) mp_neg(quotient);
  return(status);
}


word16 CRSALib::mp_shortdiv(register unitptr quotient,
  register unitptr dividend,register word16 divisor)
{
  int bits;
  short dprec;
  register unit bitmask;
  register word16 remainder;
  if (!divisor)
    return (N_NEG_VAL);
  remainder=0;
  mp_init(quotient,0);

  {
    dprec = significance(dividend);
    if (!dprec) return(0);
    bits = ((dprec) << 4);
    (dividend) = ((dividend)+(dprec)-1);
    bitmask = ((unit) 0x8000);
    while (!(*(dividend) & bitmask))
    {
      bitmask >>= 1;
      bits--;
    }
  };

  (quotient) = ((quotient)+(dprec)-1);

  while (bits--)
  {
    remainder <<= 1;
    if ((*(dividend) & bitmask))
      remainder++;
    if (remainder >= divisor)
    {
      remainder -= divisor;
      *(quotient) |= bitmask;
    }
    {
      if (!(bitmask >>= 1))
      {
        bitmask = ((unit) 0x8000);
        ((dividend)--);
        ((quotient)--);
      }
    };
  }
  return(remainder);
}


int CRSALib::mp_mod(register unitptr remainder,
  register unitptr dividend,register unitptr divisor)
{
  int bits;
  short dprec;
  register unit bitmask;
  if (( ((*(divisor))==(0)) && (significance(divisor)<=1) ))
    return(-1);
  mp_init(remainder,0);

  { dprec = significance(dividend);
    if (!dprec) return(0);
    bits = ((dprec) << 4);
    (dividend) = ((dividend)+(dprec)-1);
    bitmask = ((unit) 0x8000);
    while (!(*(dividend) & bitmask))
    {
      bitmask >>= 1;
      bits--;
    }
  };

  while (bits--)
  {
    mp_rotate_left(remainder,(boolean)((*(dividend) & bitmask)!=0));
    if (mp_compare(remainder,divisor) >= 0)
    mp_subb(remainder,divisor,(boolean)0);
    {
      if (!(bitmask >>= 1))
      {
        bitmask = ((unit) 0x8000);
        ((dividend)--);
      }
    };
  }
  return(0);
}


word16 CRSALib::mp_shortmod(register unitptr dividend,register word16 divisor)
{
  int bits;
  short dprec;
  register unit bitmask;
  register word16 remainder;
  if (!divisor)
    return(N_NEG_VAL);
  remainder=0;

  {
    dprec = significance(dividend);
    if (!dprec) return(0);
    bits = ((dprec) << 4);
    (dividend) = ((dividend)+(dprec)-1);
    bitmask = ((unit) 0x8000);
    while (!(*(dividend) & bitmask))
    {
      bitmask >>= 1;
      bits--;
    }
  };

  while (bits--)
  {
    remainder <<= 1;
    if ((*(dividend) & bitmask))
      remainder++;
    if (remainder >= divisor) remainder -= divisor;
    {
      if (!(bitmask >>= 1))
      {
        bitmask = ((unit) 0x8000); ((dividend)--);
      }
    };
  }
  return(remainder);
}

int CRSALib::mp_mult(register unitptr prod,
  register unitptr multiplicand,register unitptr multiplier)
{
  int bits;
  register unit bitmask;
  short mprec;
  mp_init(prod,0);
  if (( ((*(multiplicand))==(0)) && (significance(multiplicand)<=1) ))
    return(0);

  mprec = significance(multiplier);
  if (!mprec) return(0);
  bits = ((mprec) << 4);
  (multiplier) = ((multiplier)+(mprec)-1);
  bitmask = ((unit) 0x8000);
  while (!(*(multiplier) & bitmask))
  {
    bitmask >>= 1;
    bits--;
  }

  while (bits--)
  {
    mp_rotate_left(prod,(boolean)0);
    if ((*(multiplier) & bitmask))
    {
      mp_addc(prod,multiplicand,(boolean)0);
    }
    if (!(bitmask >>= 1))
    {
      bitmask = ((unit) 0x8000);
      ((multiplier)--);
    }
  }
  return(0);
}

void CRSALib::mp_lshift_unit(register unitptr r1)
{
  register short precision;
  register unitptr r2;
  precision = global_precision;
  (r1) = ((r1)+(precision)-1);
  r2 = r1;
  while (--precision)
    *((r1)--) = *(--(r2));
  *r1 = 0;
}

void CRSALib::stage_mp_images(unitptr images[16],unitptr r)
{
  short int i;
  images[0] = r;
  for (i=1; i<16; i++)
  {
    mp_move(images[i],images[i-1]);
    mp_rotate_left(images[i],(boolean)0);
  }
}
int CRSALib::stage_merritt_modulus(unitptr n)
{
  short int i;
  unitptr msu;
  moduli[0] = n;


  msu = ((n)+(global_precision)-1);
  msu_moduli[0] = *((msu)--);
  nmsu_moduli[0] = *msu;

  for (i=1; i<16+1; i++)
  {
    mp_move(moduli[i],moduli[i-1]);
    mp_rotate_left(moduli[i],(boolean)0);

    msu = ((moduli[i])+(global_precision)-1);
    msu_moduli[i] = *((msu)--);
    nmsu_moduli[i] = *msu;
  }
  return(0);
}

int CRSALib::merritt_modmult(register unitptr prod,
  unitptr multiplicand,register unitptr multiplier)
{

  register signedunit p_m;
  register unitptr msu_prod;
  register unitptr nmsu_prod;
  short mprec;


  stage_mp_images(mpd,multiplicand);

  msu_prod = ((prod)+(global_precision)-1);
  nmsu_prod = msu_prod;
  ((nmsu_prod)--);

  mp_init(prod,0);

  mprec = significance(multiplier);
  if (mprec==0)
    return(0);
  (multiplier) = ((multiplier)+(mprec)-1);

  while (mprec--)
  {
    mp_lshift_unit(prod);
    if (*multiplier & ((unit) 1 << (15))) mp_addc(prod,mpd[15],(boolean)0);
    if (*multiplier & ((unit) 1 << (14))) mp_addc(prod,mpd[14],(boolean)0);
    if (*multiplier & ((unit) 1 << (13))) mp_addc(prod,mpd[13],(boolean)0);
    if (*multiplier & ((unit) 1 << (12))) mp_addc(prod,mpd[12],(boolean)0);
    if (*multiplier & ((unit) 1 << (11))) mp_addc(prod,mpd[11],(boolean)0);
    if (*multiplier & ((unit) 1 << (10))) mp_addc(prod,mpd[10],(boolean)0);
    if (*multiplier & ((unit) 1 << (9))) mp_addc(prod,mpd[9],(boolean)0);
    if (*multiplier & ((unit) 1 << (8))) mp_addc(prod,mpd[8],(boolean)0);

    if (*multiplier & ((unit) 1 << (7))) mp_addc(prod,mpd[7],(boolean)0);
    if (*multiplier & ((unit) 1 << (6))) mp_addc(prod,mpd[6],(boolean)0);
    if (*multiplier & ((unit) 1 << (5))) mp_addc(prod,mpd[5],(boolean)0);
    if (*multiplier & ((unit) 1 << (4))) mp_addc(prod,mpd[4],(boolean)0);
    if (*multiplier & ((unit) 1 << (3))) mp_addc(prod,mpd[3],(boolean)0);
    if (*multiplier & ((unit) 1 << (2))) mp_addc(prod,mpd[2],(boolean)0);
    if (*multiplier & ((unit) 1 << (1))) mp_addc(prod,mpd[1],(boolean)0);
    if (*multiplier & ((unit) 1 << (0))) mp_addc(prod,mpd[0],(boolean)0);

    if (((p_m = *msu_prod-msu_moduli[16])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[16]) || ( (*nmsu_prod==nmsu_moduli[16]) && ((mp_compare(prod,moduli[16]) >= 0)) ))) ) mp_subb(prod,moduli[16],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[15])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[15]) || ( (*nmsu_prod==nmsu_moduli[15]) && ((mp_compare(prod,moduli[15]) >= 0)) ))) ) mp_subb(prod,moduli[15],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[14])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[14]) || ( (*nmsu_prod==nmsu_moduli[14]) && ((mp_compare(prod,moduli[14]) >= 0)) ))) ) mp_subb(prod,moduli[14],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[13])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[13]) || ( (*nmsu_prod==nmsu_moduli[13]) && ((mp_compare(prod,moduli[13]) >= 0)) ))) ) mp_subb(prod,moduli[13],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[12])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[12]) || ( (*nmsu_prod==nmsu_moduli[12]) && ((mp_compare(prod,moduli[12]) >= 0)) ))) ) mp_subb(prod,moduli[12],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[11])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[11]) || ( (*nmsu_prod==nmsu_moduli[11]) && ((mp_compare(prod,moduli[11]) >= 0)) ))) ) mp_subb(prod,moduli[11],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[10])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[10]) || ( (*nmsu_prod==nmsu_moduli[10]) && ((mp_compare(prod,moduli[10]) >= 0)) ))) ) mp_subb(prod,moduli[10],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[9])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[9]) || ( (*nmsu_prod==nmsu_moduli[9]) && ((mp_compare(prod,moduli[9]) >= 0)) ))) ) mp_subb(prod,moduli[9],(boolean)0);

    if (((p_m = *msu_prod-msu_moduli[8])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[8]) || ( (*nmsu_prod==nmsu_moduli[8]) && ((mp_compare(prod,moduli[8]) >= 0)) ))) ) mp_subb(prod,moduli[8],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[7])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[7]) || ( (*nmsu_prod==nmsu_moduli[7]) && ((mp_compare(prod,moduli[7]) >= 0)) ))) ) mp_subb(prod,moduli[7],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[6])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[6]) || ( (*nmsu_prod==nmsu_moduli[6]) && ((mp_compare(prod,moduli[6]) >= 0)) ))) ) mp_subb(prod,moduli[6],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[5])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[5]) || ( (*nmsu_prod==nmsu_moduli[5]) && ((mp_compare(prod,moduli[5]) >= 0)) ))) ) mp_subb(prod,moduli[5],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[4])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[4]) || ( (*nmsu_prod==nmsu_moduli[4]) && ((mp_compare(prod,moduli[4]) >= 0)) ))) ) mp_subb(prod,moduli[4],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[3])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[3]) || ( (*nmsu_prod==nmsu_moduli[3]) && ((mp_compare(prod,moduli[3]) >= 0)) ))) ) mp_subb(prod,moduli[3],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[2])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[2]) || ( (*nmsu_prod==nmsu_moduli[2]) && ((mp_compare(prod,moduli[2]) >= 0)) ))) ) mp_subb(prod,moduli[2],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[1])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[1]) || ( (*nmsu_prod==nmsu_moduli[1]) && ((mp_compare(prod,moduli[1]) >= 0)) ))) ) mp_subb(prod,moduli[1],(boolean)0);
    if (((p_m = *msu_prod-msu_moduli[0])>0) || ( (p_m==0) && ( (*nmsu_prod>nmsu_moduli[0]) || ( (*nmsu_prod==nmsu_moduli[0]) && ((mp_compare(prod,moduli[0]) >= 0)) ))) ) mp_subb(prod,moduli[0],(boolean)0);

    ((multiplier)--);
  }
  return(0);
}

void CRSALib::merritt_burn(void)

{
  unitfill0(&(mpdbuf[0][0]),(16-1)*(MAX_UNIT_PRECISION));
  unitfill0(&(moduli_buf[0][0]),(16)*(MAX_UNIT_PRECISION));
  unitfill0(msu_moduli,16+1);
  unitfill0(nmsu_moduli,16+1);
}


int CRSALib::countbits(unitptr r)
{
  int bits;
  short prec;
  register unit bitmask;
  {
    prec = significance(r);
    if (!prec) return(0);
    bits = ((prec) << 4);
    (r) = ((r)+(prec)-1);
    bitmask = ((unit) 0x8000);
    while (!(*(r) & bitmask))
    {
      bitmask >>= 1; bits--;
    }
  };
  return(bits);
}


int CRSALib::mp_modexp(register unitptr expout,register unitptr expin,
register unitptr exponent,register unitptr modulus)
{
  int bits;
  short oldprecision;
  register unit bitmask;
  unit product[(MAX_UNIT_PRECISION)];
  short eprec;

  mp_init(expout,1);
  if (( ((*(exponent))==(0)) && (significance(exponent)<=1) ))
  {
    if (( ((*(expin))==(0)) && (significance(expin)<=1) ))
      return(-1);
    return(0);
  }
  if (( ((*(modulus))==(0)) && (significance(modulus)<=1) ))
    return(-2);

  if (((signedunit) (*((modulus)+(global_precision)-1)) < 0))
    return(-2);

  if (mp_compare(expin,modulus) >= 0)
    return(-3);
  if (mp_compare(exponent,modulus) >= 0)
    return(-4);

  oldprecision = global_precision;

  (global_precision = ((((countbits(modulus)+(16+1))+15) >> 4)));


  if (stage_merritt_modulus(modulus))
  {
    (global_precision = (oldprecision));
    return(-5);
  }
  {
    eprec = significance(exponent);
    if (!eprec) return(0);
    bits = ((eprec) << 4);
    (exponent) = ((exponent)+(eprec)-1);
    bitmask = ((unit) 0x8000);
    while (!(*(exponent) & bitmask))
    {
      bitmask >>= 1;
      bits--;
    }
  };

  bits--;
  mp_move(expout,expin);
  { if (!(bitmask >>= 1)) { bitmask = ((unit) 0x8000); ((exponent)--); } };

  while (bits--)
  {
    merritt_modmult(product,expout,expout);
    mp_move(expout,product);
    if ((*(exponent) & bitmask))
    {
      merritt_modmult(product,expout,expin);
      mp_move(expout,product);
    }
    if (!(bitmask >>= 1))
    {
      bitmask = ((unit) 0x8000);
      ((exponent)--);
    }
  }
  mp_init(product,0);
  merritt_burn();

  (global_precision = (oldprecision));
  return(0);
}

int CRSALib::rsa_decrypt(unitptr M, unitptr C,
  unitptr d, unitptr p, unitptr q, unitptr u)
{
  unit p2[(MAX_UNIT_PRECISION)];
  unit q2[(MAX_UNIT_PRECISION)];
  unit temp1[(MAX_UNIT_PRECISION)];
  unit temp2[(MAX_UNIT_PRECISION)];
  int status;

  mp_init(M,1);

  if (mp_compare(p,q) >= 0)
  {
    unitptr t;
    t = p;  p = q; q = t;
  }

  mp_move(temp1,p);
  mp_dec(temp1);
  mp_mod(temp2,d,temp1);
  mp_mod(temp1,C,p);
  status = mp_modexp(p2,temp1,temp2,p);
  if (status < 0)
    return(status);

  mp_move(temp1,q);
  mp_dec(temp1);
  mp_mod(temp2,d,temp1);
  mp_mod(temp1,C,q);
  status = mp_modexp(q2,temp1,temp2,q);
  if (status < 0)
    return(status);

  if (mp_compare(p2,q2) == 0)
    mp_move(M,p2);
  else
  {
    if (mp_subb(q2,p2,(boolean)0))
      mp_addc(q2,q,(boolean)0);

    mp_mult(temp1,q2,u);
    mp_mod(temp2,temp1,q);
    mp_mult(temp1,p,temp2);
    mp_addc(temp1,p2,(boolean)0);
    mp_move(M,temp1);
  }

  mp_init(p2,0);
  mp_init(q2,0);
  mp_init(temp1,0);
  mp_init(temp2,0);

  return(0);
}

int CRSALib::mp_sqrt(unitptr quotient,unitptr dividend)
{
  register char next2bits;
  register unit dvdbitmask,qbitmask;
  unit remainder[(MAX_UNIT_PRECISION)],rjq[(MAX_UNIT_PRECISION)],
    divisor[(MAX_UNIT_PRECISION)];
  unsigned int qbits,qprec,dvdbits,dprec,oldprecision;
  int notperfect;

  mp_init(quotient,0);
  if (((signedunit) (*((dividend)+(global_precision)-1)) < 0))
  {
    mp_dec(quotient);
    return(-1);
  }

  {
    dprec = significance(dividend);
    if (!dprec) return(0);
    dvdbits = ((dprec) << 4);
    (dividend) = ((dividend)+(dprec)-1);
    dvdbitmask = ((unit) 0x8000);
    while (!(*(dividend) & dvdbitmask))
    {
      dvdbitmask >>= 1;
      dvdbits--;
    }
  };

  if (dvdbits==1)
  {
    mp_init(quotient,1);
    return(0);
  }


  qbits = (dvdbits+1) >> 1;
  qprec = (((qbits)+15) >> 4);

  (quotient) = ((quotient)+(qprec)-1);
  qbitmask = ((unit) 1 << ((qbits-1) & (16-1))) ;

  oldprecision = global_precision;
  (global_precision = ((((qbits+3)+15) >> 4)));

  *(quotient) |= qbitmask;
  {
    if (!(qbitmask >>= 1))
    {
      qbitmask = ((unit) 0x8000);
      ((quotient)--);
    }
  };

  mp_init(rjq,1);

  if (!(dvdbits & 1))
  {
    next2bits = 2;
    {
      if (!(dvdbitmask >>= 1))
      {
        dvdbitmask = ((unit) 0x8000);
        ((dividend)--);
      }
    };
    dvdbits--;
    if ((*(dividend) & dvdbitmask))
      next2bits++;
    {
      if (!(dvdbitmask >>= 1))
      {
        dvdbitmask = ((unit) 0x8000);
        ((dividend)--);
      }
    };
    dvdbits--;
  }
  else
  {
    next2bits = 1;
    {
      if (!(dvdbitmask >>= 1))
      {
        dvdbitmask = ((unit) 0x8000);
        ((dividend)--);
      }
    };
    dvdbits--;
  }

  mp_init(remainder,next2bits-1);

  while (dvdbits)
  {
    next2bits=0;
    if ((*(dividend) & dvdbitmask)) next2bits=2;
    {
      if (!(dvdbitmask >>= 1))
      {
        dvdbitmask = ((unit) 0x8000);
        ((dividend)--);
      }
    };
    dvdbits--;
    if ((*(dividend) & dvdbitmask))
      next2bits++;
    if (!(dvdbitmask >>= 1))
    {
      dvdbitmask = ((unit) 0x8000);
      ((dividend)--);
    }
    dvdbits--;
    mp_rotate_left(remainder,(boolean)((next2bits&2)!=0));
    mp_rotate_left(remainder,(boolean)((next2bits&1)!=0));

    mp_move(divisor,rjq);
    mp_rotate_left(divisor,0);
    mp_rotate_left(divisor,1);
    if (mp_compare(remainder,divisor) >= 0)
    {
      mp_subb(remainder,divisor,(boolean)0);
      *(quotient) |= qbitmask;
      mp_rotate_left(rjq,1);
    }
    else
      mp_rotate_left(rjq,0);
    if (!(qbitmask >>= 1))
    {
      qbitmask = ((unit) 0x8000);
      ((quotient)--);
    }
  }
  notperfect = ( ((*(remainder))!=(0)) || (significance(remainder)>1) );
  (global_precision = (oldprecision));
  return(notperfect);
}
//----
