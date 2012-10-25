// Include the Ruby headers and goodies
#include <stdlib.h>
#include <ctype.h>
#include "ruby.h"
#include "signer.h"
#include "base64.h"
#include "cmdbase.h"

#define ASCII_SIZE 512
#define BUF_64_SIZE 220

// Defining a space for information and references about the module to be stored internally
VALUE cSigner;

typedef VALUE (ruby_method)(...);

// Prototype for the initialization method - Ruby calls this, not you
//extern "C" void Init_Wmutils();

// Prototype for our method 'test1' - methods are prefixed by 'method_' here
// typedef VALUE method_test1(VALUE self);
// typedef VALUE initialize(VALUE self, const char *szWMID, const char *szPwd, const char *szKeyData);

//Signer *pSign;

void signer_free(Signer *p)
{
if (p)
  delete p;
}

bool IsWmid(const char* sz)
{
  int len = strlen(sz);
  if (len != 12) return false;
  for(int i = 0; i < len; i++)
  {
    if (!isdigit(sz[i]))
    return false;
  }
  return true;
}

extern "C" VALUE signer_new(VALUE self, VALUE szWMID, VALUE szPwd, VALUE szKeyData64)
{
    Signer *pSign;

    if(NIL_P(szWMID))	rb_raise(rb_eArgError, "nil wmid");

    // check WMID
    if (! IsWmid(RSTRING_PTR(szWMID))) rb_raise(rb_eArgError, "Incorrect WMID");

    if(NIL_P(szPwd)) rb_raise(rb_eArgError, "nil password");

    if(NIL_P(szKeyData64)) rb_raise(rb_eArgError, "nil key");

    // check base64 data
    if ( RSTRING_LEN(szKeyData64) != 220 ) rb_raise(rb_eArgError, "Illegal size for base64 keydata");

    char KeyBuffer[ASCII_SIZE];
    int bytes = code64( ENCODE, KeyBuffer, ASCII_SIZE, RSTRING_PTR(szKeyData64), BUF_64_SIZE );

    // check encoded key
    if ( bytes != 164) rb_raise(rb_eArgError, "Illegal size for keydata");

    pSign = new Signer(RSTRING_PTR(szWMID), RSTRING_PTR(szPwd), "");
    VALUE tdata = Data_Wrap_Struct(self, 0, signer_free, pSign);

    pSign->isIgnoreKeyFile = TRUE;
    pSign->Key64Flag = TRUE;

    if (pSign) pSign->SetKeyFromCL( TRUE, KeyBuffer );

    return tdata;
}

extern "C" VALUE signer_init(VALUE self)
{
    return self;
}

extern "C" VALUE signer_sign(VALUE self, VALUE szIn)
{
    VALUE ret;
    ret = rb_str_new2("");

    Signer *pSign;

    Data_Get_Struct(self, Signer, pSign);

    if(NIL_P(szIn)) rb_raise(rb_eArgError, "nil for sign");

    if (pSign)
    {
      szptr szSign;
			if (pSign->Sign(RSTRING_PTR(szIn), szSign))
			{
		 	    ret = rb_str_new2((char *)(const char *)szSign);
			}
    }

    int err_no = pSign->ErrorCode();
    if (err_no){
			rb_raise(rb_eStandardError, "Signer error: %d", err_no);
    }

   return ret;
}

// The initialization method for this module
extern "C" void Init_wmsigner()
{
    cSigner = rb_define_class("Signer", rb_cObject);
    rb_define_singleton_method(cSigner, "new", (ruby_method*) &signer_new, 3);
    rb_define_method(cSigner, "initialize", (ruby_method*) &signer_init, 0);
    rb_define_method(cSigner, "sign", (ruby_method*) &signer_sign, 1);
}
