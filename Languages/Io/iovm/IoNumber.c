/*#io
Number ioDoc(
             docCopyright("Steve Dekorte", 2002)
             docLicense("BSD revised")
             docObject("Number")
             docInclude("_ioCode/Number.io")
             docDescription("A container for a double (a 64bit floating point number on most platforms).")
		   docCategory("Core")
             */

#include "IoNumber.h"
#include "IoObject.h"
#include "IoState.h"
#include "IoSeq.h"
#include "IoSeq.h"
#include "IoDate.h"
#include "IoState.h"
#include <math.h>
#include <ctype.h>
#include <assert.h>

#include <setjmp.h>
#if defined(_BSD_PPC_SETJMP_H_)
#include <machine/limits.h>
#else
#include <limits.h>
#endif

#if defined(__SYMBIAN32__)
/* TODO: Fix symbian constants */
#define FLT_MAX 0.0
#define FLT_MIN 0.0
#else
#include <float.h>
#endif


#define NIVAR(self) CNUMBER(self)

IoNumber *IoNumber_numberForDouble_canUse_(IoNumber *self, double n, IoNumber *other)
{
    if (NIVAR(self)  == n) return self;
    if (NIVAR(other) == n) return other;
    return IONUMBER(n);
}

IoTag *IoNumber_tag(void *state)
{
    IoTag *tag = IoTag_newWithName_("Number");
    tag->state = state;
    tag->cloneFunc = (TagCloneFunc *)IoNumber_rawClone;
    tag->freeFunc = (TagFreeFunc *)IoNumber_free;
    tag->compareFunc = (TagCompareFunc *)IoNumber_compare;
    tag->writeToStoreOnStreamFunc = (TagWriteToStoreOnStreamFunc *)IoNumber_writeToStore_stream_;
    tag->readFromStoreOnStreamFunc = (TagReadFromStoreOnStreamFunc *)IoNumber_readFromStore_stream_;
    assert(sizeof(double) <= sizeof(void *)*2);
    /*printf("Number tag = %p\n", (void *)tag);*/
    return tag;
}

void IoNumber_writeToStore_stream_(IoNumber *self, IoStore *store, BStream *stream)
{
    BStream_writeTaggedDouble_(stream, NIVAR(self));
}

void *IoNumber_readFromStore_stream_(IoNumber *self, IoStore *store, BStream *stream)
{
    NIVAR(self) = BStream_readTaggedDouble(stream);
    return self;
}

// #define IONUMBER_IS_MUTABLE 

IoNumber *IoNumber_proto(void *state)
{
    IoMethodTable methodTable[] = {
	{"asNumber", IoNumber_asNumber},
	{"add", IoNumber_add_},
	{"+", IoNumber_add_},
	{"-", IoNumber_subtract},
	{"*", IoNumber_multiply},
	{"/", IoNumber_divide},
	//{"print", IoNumber_printNumber},
	//{"linePrint", IoNumber_linePrint},
        
	{"asString", IoNumber_asString},
	{"asBuffer", IoNumber_asBuffer},
	{"asCharacter", IoNumber_asCharacter},
    //{"asDate", IoNumber_asDate},
        
	{"abs", IoNumber_abs},
	{"acos", IoNumber_acos},
	{"asin", IoNumber_asin},
	{"atan", IoNumber_atan},
	{"atan2", IoNumber_atan2},
	{"ceil", IoNumber_ceil},
	{"cos", IoNumber_cos},
     // {"deg", IoNumber_deg}
	{"exp", IoNumber_exp},
	{"factorial", IoNumber_factorial},
	{"floor", IoNumber_floor},
	{"log", IoNumber_log},
	{"log10", IoNumber_log10},
	{"max", IoNumber_max},
	{"min", IoNumber_min},
	{"%", IoNumber_mod},
	{"mod", IoNumber_mod},
	//{"^", IoNumber_pow},
	{"**", IoNumber_pow},
	{"pow", IoNumber_pow},
	{"roundDown", IoNumber_roundDown},
	{"roundUp", IoNumber_roundUp},
	{"sin", IoNumber_sin},
	{"sqrt", IoNumber_sqrt},
	{"squared", IoNumber_squared},
	{"cubed", IoNumber_cubed},
	{"tan", IoNumber_tan},
	{"toggle", IoNumber_toggle},
        
    // logic operations 
        
	{"&", IoNumber_bitwiseAnd},
	{"|", IoNumber_bitwiseOr},
        
	{"bitwiseAnd", IoNumber_bitwiseAnd},
	{"bitwiseOr", IoNumber_bitwiseOr},
	{"bitwiseXor", IoNumber_bitwiseXor},
	{"bitwiseComplement", IoNumber_bitwiseComplement},
	{"shiftLeft", IoNumber_bitShiftLeft},
	{"shiftRight", IoNumber_bitShiftRight},
        
    // even and odd 
        
	{"isEven", IoNumber_isEven},
	{"isOdd", IoNumber_isOdd},
        
    // character operations
        
	{"isAlphaNumeric", IoNumber_isAlphaNumeric},
	{"isLetter", IoNumber_isLetter},
	{"isControlCharacter", IoNumber_isControlCharacter},
	{"isDigit", IoNumber_isDigit},
	{"isGraph", IoNumber_isGraph},
	{"isLowercase", IoNumber_isLowercase},
	{"isUppercase", IoNumber_isUppercase},
	{"isPrint", IoNumber_isPrint},
	{"isPunctuation", IoNumber_isPunctuation},
	{"isSpace", IoNumber_isSpace},
	{"isHexDigit", IoNumber_isHexDigit},
        
	{"Lowercase", IoNumber_Lowercase},
	{"upperCase", IoNumber_upperCase},
	{"asLowercase", IoNumber_Lowercase},
	{"asUppercase", IoNumber_upperCase},
        
	{"between", IoNumber_between},
	{"clip", IoNumber_clip},
	{"negate", IoNumber_negate},
	{"at", IoNumber_at},
        
	{"integerMax", IoNumber_integerMax},
	{"integerMin", IoNumber_integerMin},
	{"longMax", IoNumber_longMax},
	{"longMin", IoNumber_longMin},
	{"shortMax", IoNumber_shortMax},
	{"shortMin", IoNumber_shortMin},
	{"unsignedLongMax", IoNumber_unsignedLongMax},
	{"unsignedIntMax", IoNumber_unsignedIntMax},
	{"floatMax", IoNumber_floatMax},
	{"floatMin", IoNumber_floatMin},
        
	{"repeatTimes", IoNumber_repeat},
	{"repeat", IoNumber_repeat},
        
	{NULL, NULL},
    };
    
    IoObject *self = IoObject_new(state);
        
    self->tag = IoNumber_tag(state);
    NIVAR(self) = 0;
    IoState_registerProtoWithFunc_((IoState *)state, self, IoNumber_proto);
    
    IoObject_addMethodTable_(self, methodTable);
    return self;
}

IoNumber *IoNumber_rawClone(IoNumber *proto)
{
    IoObject *self = IoObject_rawClonePrimitive(proto);
    NIVAR(self) = NIVAR(proto);
    return self;
}

IoNumber *IoNumber_newWithDouble_(void *state, double n)
{
    IoNumber *proto = IoState_protoWithInitFunction_((IoState *)state, IoNumber_proto);
    IoNumber *self = IOCLONE(proto); // since Numbers have no refs, we can avoid IOCLONE 
    NIVAR(self) = n;
    return self;
}

IoNumber *IoNumber_newCopyOf_(IoNumber *self)
{ 
    return IONUMBER(NIVAR(self)); 
}

void IoNumber_copyFrom_(IoNumber *self, IoNumber *number)
{ 
    NIVAR(self) = NIVAR(number); 
}

void IoNumber_free(IoNumber *self)
{
    /* need this so Object won't try to free IoObject_dataPointer(self) */
}

int IoNumber_asInt(IoNumber *self) 
{ 
    return (int)(NIVAR(self)); 
}

long IoNumber_asLong(IoNumber *self) 
{ 
    return (long)(NIVAR(self)); 
}

float IoNumber_asFloat(IoNumber *self) 
{ 
    return (float)NIVAR(self); 
}

double IoNumber_asDouble(IoNumber *self) 
{ 
    return (double)NIVAR(self); 
}

int IoNumber_compare(IoNumber *self, IoNumber *v)
{
    if (ISNUMBER(v))
    {
        if (NIVAR(self) == NIVAR(v)) 
        {
            return 0;
        }
        return (NIVAR(self) > NIVAR(v)) ? 1 : -1;
    }
    return ((ptrdiff_t)self->tag) - ((ptrdiff_t)v->tag);
}

void IoNumber_Double_intoCString_(double n, char *s, size_t maxSize)
{
    if (n == (int)n)
    { 
        snprintf(s, maxSize, "%d", (int)n); 
    }
    else if (n > INT_MAX)
    {
        snprintf(s, maxSize, "%e", n);
    }
    else
    {
        int l;
        
        snprintf(s, maxSize, "%f", n);
        
        // remove the trailing zeros ex: 10.00 -> 10 
        
        l = strlen(s) - 1;
        
        while (l > 0)
        {
            if (s[l] == '0') { s[l] = 0x0; l--; continue; }
            if (s[l] == '.') { s[l] = 0x0; l--; break; }
            break;
        }
    }
}

void IoNumber_print(IoNumber *self)
{
    double d = NIVAR(self);
    char s[128];
    
    IoNumber_Double_intoCString_(d, s, 127);
    IoState_print_(IOSTATE, "%s", s); 
}

// ----------------------------------------------------------- 

#ifdef _WIN32
#include <winsock2.h>
#else
#include <arpa/inet.h>
#endif

IoObject *IoNumber_htonl(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("htonl", 
            "Returns a new number with the first 4 bytes of the receiver switched from
host to network byte order.")
    */
    
    IoNumber *num = IONUMBER(0);
    IoObject_setDataUint32_(num, htonl(IoObject_dataUint32(self)));
    return num;
}

IoObject *IoNumber_ntohl(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("htonl", 
            "Returns a new number with the first 4 bytes of the receiver switched from
network to host byte order.")
    */
    
	IoNumber *num = IONUMBER(0);
	IoObject_setDataUint32_(num, ntohl(IoObject_dataUint32(self)));
	return num;
}

// ----------------------------------------------------------- 

IoObject *IoNumber_asNumber(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("asNumber", "Returns self.")
    */
    return self;
}

IoObject *IoNumber_add_(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("+(aNumber)", 
            "Returns a new number that is the sum of the receiver and aNumber.")
    */
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return IONUMBER(NIVAR(self) + NIVAR(other));
}


IoObject *IoNumber_subtract(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("-(aNumber)", 
            "Returns a new number that is the difference of the receiver and aNumber.")
    */
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return IONUMBER(NIVAR(self) - NIVAR(other));
}

IoObject *IoNumber_divide(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("/(aNumber)", 
            "Returns a new number with the value of the receiver diveded by aNumber.")
    */
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return IONUMBER(NIVAR(self) / NIVAR(other));
}

IoObject *IoNumber_multiply(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("*(aNumber)", 
            "Returns a new number that is the product of the receiver and aNumber.")
    */
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return IONUMBER(NIVAR(self) * NIVAR(other));
}

IoObject *IoNumber_printNumber(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("print", "Prints the number.")
    */
    char s[24];
    memset(s, 0x0, 24);
    IoNumber_Double_intoCString_(NIVAR(self), s, 24);
    IoState_print_((IoState *)IOSTATE, s);
    return self;
}

IoObject *IoNumber_linePrint(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*
    docSlot("linePrint", "Prints the Number and a new line character.")
    */
    IoNumber_printNumber(self, locals, m);
    IoState_print_((IoState *)IOSTATE, "\n");
    return self;
}

IoObject *IoNumber_justAsString(IoNumber *self, IoObject *locals, IoMessage *m)
{
    IoSymbol *string;
    int size = 1000;
    char *s = (char *)malloc(size);
    memset(s, 0x0, size);
    IoNumber_Double_intoCString_(NIVAR(self), s, 1000);
    string = IoState_symbolWithCString_((IoState *)IOSTATE, s);
    free(s);
    return string;
}

IoObject *IoNumber_asCharacter(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("asCharacter", 
            "Returns a String containing a single character whose 
value is the ascii value of the first byte of the receiver.")
    */
    char s[2];
    s[0] = (char)NIVAR(self);
    s[1] = 0x0;
    return IoState_symbolWithCString_length_((IoState *)IOSTATE, s, 1);
}

IoObject *IoNumber_asBuffer(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("asBuffer(optionalNumberOfBytes)", 
            "Returns a Buffer containing a the number of bytes specified by 
optionalNumberOfBytes (up to the size of a double on the platform) of the reciever. 
If no optionalNumberOfBytes is specified, it is assumed to be the number of bytes 
in a double on the host platform.")
    
    */
    IoNumber *byteCount = IoMessage_locals_valueArgAt_(m, locals, 0);
    int bc = sizeof(double);
    
    if (!ISNIL(byteCount)) 
    {
        bc = NIVAR(byteCount);
    }
    return IoSeq_newWithData_length_(IOSTATE, (unsigned char *)&(NIVAR(self)), bc);
}

IoObject *IoNumber_asString(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("asString(optionalIntegerDigits, optionalFactionDigits)", 
            """Returns a string representation of the receiver. For example:
<pre>1234.5678 asString(0, 2)</pre>
would return:
<pre>$1234.56</pre>
""")
    */
    if (IoMessage_argCount(m) >= 1)
    {
        int whole = IoMessage_locals_intArgAt_(m, locals, 0);
        int part = 6;
        char s[32];
        
        if (IoMessage_argCount(m) >= 2)
        { 
            part = abs(IoMessage_locals_intArgAt_(m, locals, 1)); 
        }
        
        part  = abs(part);
        whole = abs(whole);
        
        if (whole > 15) whole = 15;
        if (part > 15)  part = 15;
        
        if (whole && part)
        {
            snprintf(s, 32, "%*.*f", whole, part, NIVAR(self));
        }
        else if (whole)
        {
            snprintf(s, 32, "%*d", whole, (int) NIVAR(self));
        }
        else if (part)
        {
            snprintf(s, 32, "%.*f", part, NIVAR(self));
        }
        else
        {
            snprintf(s, 32, "%d", (int) NIVAR(self));
        }
        
        return IOSYMBOL(s);
    }
    
    return IoNumber_justAsString(self, locals, m);
}

/*
IoObject *IoNumber_asDate(IoNumber *self, IoObject *locals, IoMessage *m)
{ 
     return IoDate_newWithNumber_((IoState *)IOSTATE, NIVAR(self)); 
}
*/

IoObject *IoNumber_abs(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("abs", 
            "Returns a number with the absolute value of the receiver.")
    */
    return (NIVAR(self) < 0) ? (IoObject *)IONUMBER(-NIVAR(self)) : (IoObject *)self;
}

IoObject *IoNumber_acos(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("acos", 
            "Returns a number with the arc cosine of the receiver.")
    */
    return IONUMBER(acos(NIVAR(self)));
}

IoObject *IoNumber_asin(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("asin", 
            "Returns a number with the arc sine of the receiver.")
    */
    return IONUMBER(asin(NIVAR(self)));
}

IoObject *IoNumber_atan(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("atan", 
            "Returns a number with the arc tangent of the receiver.")
    */
    return IONUMBER(atan(NIVAR(self)));
}

IoObject *IoNumber_atan2(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("atan2(aNumber)", 
            "Returns a number with the arc tangent of y/x where y is the receiver and x is aNumber.")
    */
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return IONUMBER(atan2(NIVAR(self), NIVAR(other)));
}

IoObject *IoNumber_ceil(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("ceil", 
            "Returns the a number with the receiver's value rounded up to 
the nearest integer if it's fractional component is greater than 0.")
    */
    return IONUMBER(ceil(NIVAR(self)));
}

IoObject *IoNumber_cos(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("cos", 
            "Returns the cosine of the receiver.")
    */
    return IONUMBER(cos(NIVAR(self)));
}

/*
IoObject *IoNumber_deg(IoNumber *self, IoObject *locals, IoMessage *m)
{ 
    return IONUMBER(deg(NIVAR(self))); 
}
*/

IoObject *IoNumber_exp(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("exp", 
            "Returns e to the power of the receiver.")
    */
    return IONUMBER(exp(NIVAR(self)));
}

IoObject *IoNumber_factorial(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("factorial", 
            "Returns the factorial of the receiver.")
    */
    int n = NIVAR(self);
    double v = 1;
    while (n) 
    { 
        v *= n; 
        n--; 
    }
    return IONUMBER(v);
}

IoObject *IoNumber_floor(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("floor", 
            "Returns the a number with the receiver's value rounded 
down to the nearest integer if it's fractional component is not 0.")
    */
    return IONUMBER(floor(NIVAR(self)));
}

IoObject *IoNumber_log(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("log", "Returns the natural logarithm of the receiver.")
    */
    
    return IONUMBER(log(NIVAR(self)));
}

IoObject *IoNumber_log10(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("log10", "Returns the base 10 logarithm of the receiver.")
    */
    
    return IONUMBER(log10(NIVAR(self)));
}

IoObject *IoNumber_max(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("max(aNumber)", 
            "Returns the greater of the receiver and aNumber.")
    */
    
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return (NIVAR(self) > NIVAR(other)) ? (IoObject *)self :(IoObject *)other;
}

IoObject *IoNumber_min(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("min(aNumber)", "Returns the lesser of the receiver and aNumber.")
    */
    
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return (NIVAR(self) < NIVAR(other)) ? (IoObject *)self : (IoObject *)other;
}

IoObject *IoNumber_mod(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("%(aNumber)", "Returns the receiver modulus aNumber.")
    */
    
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return IONUMBER(fmod(NIVAR(self), NIVAR(other)));
}

/*
IoObject *IoNumber_modf(IoNumber *self, IoObject *locals, IoMessage *m)
{
     IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
     if (NIVAR(self) < NIVAR(other)); return self;
     return other;
}
 
IoObject *IoNumber_rad(IoNumber *self, IoObject *locals, IoMessage *m)
 */

IoObject *IoNumber_pow(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("pow(aNumber)", 
            "Returns the value of the receiver to the aNumber power.")
    */
    /*#io
    docSlot("**(aNumber)", 
            "Same as pow(aNumber).")
    */    
    IoNumber *other = IoMessage_locals_numberArgAt_(m, locals, 0);
    return IONUMBER(pow(NIVAR(self), NIVAR(other)));
}

IoObject *IoNumber_roundDown(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("roundDown", 
            "Returns the a number with the receiver's value rounded 
down to the nearest integer if it's fraction component is <= .5.")
    */
    long n = NIVAR(self);
    double v = NIVAR(self) > n + 0.5 ? n + 1 : n;
    return IONUMBER(v);
}

IoObject *IoNumber_roundUp(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("roundUp", 
            "Returns the a number with the receiver's value rounded up to 
the nearest integer if it's fraction component is >= .5.")
    */
    
    long n = NIVAR(self);
    double v = NIVAR(self) >= n + 0.5 ? n + 1 : n;
    return IONUMBER(v);
}

IoObject *IoNumber_sin(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("sin", 
            "Returns the sine of the receiver.")
    */
    
    return IONUMBER(sin(NIVAR(self)));
}

IoObject *IoNumber_sqrt(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("sqrt", 
            "Returns the square root of the receiver.")
    */
    
    return IONUMBER(sqrt(NIVAR(self)));
}

IoObject *IoNumber_squared(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("sqrt", "Returns the square root of the receiver.")
    */
    
    double v = NIVAR(self);
    return IONUMBER(v * v);
}

IoObject *IoNumber_cubed(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("cubed", "Returns the cube of the receiver.")
    */
    
    double v = NIVAR(self);
    return IONUMBER(v * v * v);
}


IoObject *IoNumber_tan(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("tan", "Returns the tangent of the receiver.")
    */
    
    return IONUMBER(tan(NIVAR(self)));
}

/*
IoObject *IoNumber_frexp(IoNumber *self, IoObject *locals, IoMessage *m)
{ 
     return IONUMBER( frexp(NIVAR(self)) ); 
}
 
IoObject *IoNumber_ldexp(IoNumber *self, IoObject *locals, IoMessage *m)
{ 
     return IONUMBER( ldexp(NIVAR(self)) );
}
*/

IoObject *IoNumber_toggle(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("toggle", "Returns 1 if the receiver is 0. Returns 0 otherwise.")
    */
    
    return (NIVAR(self))? (IoObject *)IONUMBER(0) : (IoObject *)IONUMBER(1);
}

/* --- bitwise operations ---------------------------------------- */

IoObject *IoNumber_bitwiseAnd(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("&(aNumber)", "Returns a new number with the bitwise AND of the receiver and aNumber.")
    */
    
    long other = IoMessage_locals_longArgAt_(m, locals, 0);
    return IONUMBER(((long)NIVAR(self) & other));
}

IoObject *IoNumber_bitwiseOr(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("|(aNumber)", "Returns a new number with the bitwise OR of the receiver and aNumber.")
    */
    
    long other = IoMessage_locals_longArgAt_(m, locals, 0);
    long n = NIVAR(self);
    long r = n | other;
    return IONUMBER(r);
}

IoObject *IoNumber_bitwiseXor(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("bitwiseXor(aNumber)", 
            "Returns a new number with the bitwise XOR of the receiver and aNumber.")
    */
    
    long other = IoMessage_locals_longArgAt_(m, locals, 0);
    long r = (double)((long)NIVAR(self) ^ other);
    return IONUMBER(r);
}

IoObject *IoNumber_bitwiseComplement(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("bitwiseComplement", 
            "Returns a new number with the bitwise complement of the 
receiver. (Turns the 0 bits of become 1s and the 1 bits become 0s. )")
    */
    
    long r = (double)(~(long)NIVAR(self));
    return IONUMBER(r);
}

IoObject *IoNumber_bitShiftLeft(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("shiftLeft(aNumber)", 
            "Shifts the bits of the receiver left by the number of places specified by aNumber.")
    */
    
    long other = IoMessage_locals_longArgAt_(m, locals, 0);
    long r = (double)((long)NIVAR(self) << other);
    return IONUMBER(r);
}

IoObject *IoNumber_bitShiftRight(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("shiftRight(aNumber)", 
            "Shifts the bits of the receiver right by the number of places specified by aNumber.")
    */
    
    long other = IoMessage_locals_longArgAt_(m, locals, 0);
    long r =  (double)((long)NIVAR(self) >> (long)other);
    return IONUMBER(r);
}

// even and odd ------------------------------

IoObject *IoNumber_isEven(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isEven", 
            "Returns self if integer form of the receiver is even. Otherwise returns Nil.")
    */
    
    int n = NIVAR(self);
    return IOBOOL(self, 0 == (n & 0x01));
}

IoObject *IoNumber_isOdd(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isOdd", 
            "Returns self if integer form of the receiver is even. Otherwise returns Nil.")
    */
    
    int n = NIVAR(self);
    return IOBOOL(self, 0x01 == (n & 0x01));
}

// character operations --------------------------------- 

IoObject *IoNumber_isAlphaNumeric(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isAlphaNumeric", 
            "Returns self if the receiver is an alphanumeric 
character value. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, isalnum((int)NIVAR(self)));
}

IoObject *IoNumber_isLetter(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isLetter", 
            "eturns self if the receiver is an alphanetic character value. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, isalpha((int)NIVAR(self)));
}

IoObject *IoNumber_isControlCharacter(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isControlCharacter", 
            "Returns self if the receiver is an control 
character value. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, iscntrl((int)NIVAR(self)));
}

IoObject *IoNumber_isDigit(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isDigit", 
            "Returns self if the receiver is an numeric 
digit character value. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, isdigit((int)NIVAR(self)));
}

IoObject *IoNumber_isGraph(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isGraph", 
            "Returns self if the receiver is a printing character 
value except space. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, isgraph((int)NIVAR(self)));
}

IoObject *IoNumber_isLowercase(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isLowercase", 
            "Returns self if the receiver is an lower case 
character value. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, islower((int)NIVAR(self)));
}

IoObject *IoNumber_isUppercase(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isUppercase", 
            "Returns self if the receiver is an upper case 
character value. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, isupper((int)NIVAR(self)));
}

IoObject *IoNumber_isPrint(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isPrint", 
            "Returns self if the receiver is an printing character 
value, including space. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, isprint((int)NIVAR(self)));
}

IoObject *IoNumber_isPunctuation(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isPunctuation", 
            "Returns self if the receiver is an printing character 
value, except space letter or digit. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, ispunct((int)NIVAR(self)));
}

IoObject *IoNumber_isSpace(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isSpace", 
            "Returns self if the receiver is a space, formfeed, 
newline carriage return, tab or vertical tab character value. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, isspace((int)NIVAR(self)));
}

IoObject *IoNumber_isHexDigit(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isHexDigit", 
            "Returns self if the receiver is hexidecimal digit 
character value. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, isxdigit((int)NIVAR(self)));
}

// case ---------------------------------

IoObject *IoNumber_Lowercase(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("Lowercase", 
            "Returns a new Number containing a lower case version of the receiver.")
    */
    
    int r = tolower((int)NIVAR(self));
    return IONUMBER(r);
}

IoObject *IoNumber_upperCase(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("upperCase", 
            "Returns a new Number containing a upper case version of the receiver.")
    */
    
    int r = toupper((int)NIVAR(self));
    return IONUMBER(r);
}

IoObject *IoNumber_between(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("between(aNumber1, aNumber2)", 
            "Returns the receiver if the receiver's value is between or
equal to aNumber1 and aNumber2, otherwise returns nil.")
    */
    
    double a = IoMessage_locals_doubleArgAt_(m, locals, 0);
    double b = IoMessage_locals_doubleArgAt_(m, locals, 1);
    double n = NIVAR(self);
    
    return IOBOOL(self, ((n >= a) && (n <= b)) || (n <= a && (n >= b)));
}

IoObject *IoNumber_clip(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("clip(aNumber1, aNumber2)", 
            "Returns self if the receiver is between aNumber1 and aNumber2. 
Returns aNumber1 if it is less than aNumber1. Returns aNumber2 if it is greater than aNumber2.")
    */
    
    double a = IoMessage_locals_doubleArgAt_(m, locals, 0);
    double b = IoMessage_locals_doubleArgAt_(m, locals, 1);
    double n = NIVAR(self);
    
    if (n < a) n = a;
    if (n > b) n = b;
    
    return IONUMBER(n);
}

IoObject *IoNumber_negate(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("negate", 
            "Returns new number that is negated version of the receiver.")
    */
    
    return IONUMBER(-NIVAR(self));
}

IoObject *IoNumber_at(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("at(bitIndexNumber)", 
            "Returns a new Number containing 1 if the receiver cast to a long 
has it's  bit set to 1 at bitIndexNumber. Otherwise returns 0.")
    */
    
    int i = IoMessage_locals_intArgAt_(m, locals, 0);
    long l = (long)NIVAR(self);
    
    IOASSERT((i >= 0) && (i < sizeof(double)*8), "index out of bit bounds");
    
    l = l >> i;
    l = l & 0x1;
    return IONUMBER(l);
}

// limits ------------------------------------

IoObject *IoNumber_integerMax(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("integerMax", "Returns the maximum integer value.")
    */
    
    return IONUMBER(INT_MAX);
}

IoObject *IoNumber_integerMin(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("integerMin", "Returns the minimum integer value.")
    */
    
    return IONUMBER(INT_MIN);
}


IoObject *IoNumber_longMax(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("longMax", "Returns the maximum long value.")
    */
    
    return IONUMBER(LONG_MAX);
}

IoObject *IoNumber_longMin(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("longMin", "Returns the minimum long value.")
    */
    
    return IONUMBER(LONG_MIN);
}


IoObject *IoNumber_shortMax(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("shortMax", "Returns the maximum short value.")
    */
    
    return IONUMBER(SHRT_MAX);
}

IoObject *IoNumber_shortMin(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("shortMin", "Returns the minimum short value.")
    */
    
    return IONUMBER(SHRT_MIN);
}

IoObject *IoNumber_unsignedLongMax(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("unsignedLongMax", "Returns the maximum unsigned long value.")
    */
    
    return IONUMBER(ULONG_MAX);
}

IoObject *IoNumber_unsignedIntMax(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("unsignedIntMax", "Returns the maximum unsigned int value.")
    */
    
    return IONUMBER(UINT_MAX);
}

IoObject *IoNumber_unsignedShortMax(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("unsignedShortMax", "Returns the minimum unsigned int value.")
    */
    
    return IONUMBER(USHRT_MAX);
}

IoObject *IoNumber_floatMax(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("floatMax", "Returns the maximum float value.")
    */
    
    return IONUMBER(FLT_MAX);
}

IoObject *IoNumber_floatMin(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("floatMin", "Returns the minimum float value.")
    */
    
    return IONUMBER(FLT_MIN);
}

IoObject *IoNumber_doubleMax(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("floatMax", "Returns the maximum double precision float value.")
    */
    
    return IONUMBER(DBL_MAX);
}

IoObject *IoNumber_doubleMin(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("doubleMin", "Returns the minimum double precision float value.")
    */
    
    return IONUMBER(DBL_MIN);
}

// looping --------------------------------------------- 

IoObject *IoNumber_repeat(IoNumber *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("repeatTimes(optionalIndex, expression)", 
            "Evaluates message a number of times that corresponds to the receivers 
integer value. This is significantly  faster than a for() or while() loop.")
    */
    
    IoMessage_assertArgCount_receiver_(m, 1, self);
    {
        IoState *state = IOSTATE;
	IoSymbol *indexSlotName;
        IoMessage *doMessage;
        int i, max = CNUMBER(self);
        IoObject *result = IONIL(self);

        if(IoMessage_argCount(m) > 1)
        {
            indexSlotName = IoMessage_name(IoMessage_rawArgAt_(m, 0));
            doMessage = IoMessage_rawArgAt_(m, 1);
        }
        else
        {
            indexSlotName = 0;
            doMessage = IoMessage_rawArgAt_(m, 0);
        }
        
        IoState_pushRetainPool(state);
        
        for (i = 0; i < max; i ++)
        {
            /*
             if (result != locals && result != self) 
             {
                 IoState_immediatelyFreeIfUnreferenced_(state, result);
             }
             */
            
            IoState_clearTopPool(state);
            if (indexSlotName)
            {
                IoObject_setSlot_to_(locals, indexSlotName, IONUMBER(i));
            }
            result = IoMessage_locals_performOn_(doMessage, locals, locals);
            
            if (IoState_handleStatus(IOSTATE)) 
            {
                goto done;
            }
        }
        
done:
            IoState_popRetainPoolExceptFor_(IOSTATE, result);
        return result;
    }
}

