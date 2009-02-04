/*#io
Sequence ioDoc(
docCopyright("Steve Dekorte", 2002)
docLicense("BSD revised")
*/

#ifndef IOSEQ_DEFINED
#define IOSEQ_DEFINED 1

#include "IoVMApi.h"

#include "Common.h"
#include "ByteArray.h"
#include "IoObject_struct.h"
#include "IoMessage.h"

#ifdef __cplusplus
extern "C" {
#endif

IOVM_API int ISMUTABLESEQ(IoObject *self);

#define IOSEQ(data, size)  IoSeq_newWithData_length_((IoState*)IOSTATE, data, size)
#define IOSEQ_LENGTH(self) ByteArray_size((ByteArray *)(IoObject_dataPointer(self)))
#define IOSEQ_BYTES(self)  ByteArray_bytes((ByteArray *)(IoObject_dataPointer(self)))
#define ISSEQ(self)	   IoObject_hasCloneFunc_(self, (TagCloneFunc *)IoSeq_rawClone)

#define WHITESPACE         " \t\n\r"

// Symbol defines 

#define IOSYMBOL(s)         IoState_symbolWithCString_((IoState*)IOSTATE, (char *)(s))
#define IOSYMBOLID(s)       (IoObject_dataPointer(self))
#define CSTRING(uString)    IoSeq_asCString(uString)
#define ISSYMBOL(self)      (self->isSymbol)
#define ISBUFFER(self)	    ISMUTABLESEQ(self)

#if !defined(IoSymbol_DEFINED) 
  #define IoSymbol_DEFINED 
  typedef IoObject IoSymbol;
  typedef IoObject IoSeq;
#endif

//#define IOSYMBOL_HASHCODE(self) ((unsigned int)(self->extraData))
#define IOSYMBOL_LENGTH(self)   ByteArray_size(((ByteArray *)(IoObject_dataPointer(self))))
#define IOSYMBOL_BYTES(self)    ByteArray_bytes(((ByteArray *)(IoObject_dataPointer(self))))

typedef IoObject *(IoSplitFunction)(void *, ByteArray *, int);

typedef IoObject IoSeq;

IOVM_API int ioSeqCompareFunc(void *s1, void *s2);
IOVM_API int ioSymbolFindFunc(void *s, void *ioSymbol);

IOVM_API int IoObject_isStringOrBuffer(IoObject *self);
IOVM_API int IoObject_isNotStringOrBuffer(IoObject *self);

IOVM_API IoSeq *IoSeq_proto(void *state);
IOVM_API IoSeq *IoSeq_protoFinish(IoSeq *self);

IOVM_API IoSeq *IoSeq_rawClone(IoSeq *self);
IOVM_API IoSeq *IoSeq_new(void *state);
IOVM_API IoSeq *IoSeq_newWithByteArray_copy_(void *state, ByteArray *ba, int copy);
IOVM_API IoSeq *IoSeq_newWithData_length_(void *state, const unsigned char *s, size_t length);
IOVM_API IoSeq *IoSeq_newWithDatum_(void *state, Datum *d);
IOVM_API IoSeq *IoSeq_newWithCString_length_(void *state, const char *s, size_t length);
IOVM_API IoSeq *IoSeq_newWithCString_(void *state, const char *s);
IOVM_API IoSeq *IoSeq_newFromFilePath_(void *state, const char *path);
IOVM_API IoSeq *IoSeq_rawMutableCopy(IoSeq *self);

// these Symbol creation methods should only be called by IoState 

IOVM_API IoSymbol *IoSeq_newSymbolWithCString_(void *state, const char *s);
IOVM_API IoSymbol *IoSeq_newSymbolWithData_length_(void *state, const char *s, size_t length);
IOVM_API IoSymbol *IoSeq_newSymbolWithByteArray_copy_(void *state, ByteArray *ba, int copy);

// these Symbol creation methods can be called by anyone

IOVM_API IoSymbol *IoSeq_newSymbolWithFormat_(void *state, const char *format, ...);

//

IOVM_API void IoSeq_free(IoSeq *self);
IOVM_API int IoSeq_compare(IoSeq *self, IoSeq *v);

IOVM_API char *IoSeq_asCString(IoSeq *self);
IOVM_API unsigned char *IoSeq_rawBytes(IoSeq *self);
IOVM_API ByteArray *IoSeq_rawByteArray(IoSeq *self);

IOVM_API size_t IoSeq_rawSize(IoSeq *self);
IOVM_API size_t IoSeq_rawSizeInBytes(IoSeq *self);
IOVM_API void IoSeq_rawSetSize_(IoSeq *self, size_t size);
IOVM_API void IoSeq_setIsSymbol_(IoSeq *self, int i);

// conversion 

IOVM_API double IoSeq_asDouble(IoSeq *self);
IOVM_API Datum IoSeq_asDatum(IoSeq *self);
IOVM_API IoSymbol *IoSeq_rawAsSymbol(IoSeq *self);

IOVM_API IoSymbol *IoSeq_rawAsUnquotedSymbol(IoObject *self);
IOVM_API IoSymbol *IoSeq_rawAsUnescapedSymbol(IoObject *self);

IOVM_API int IoSeq_rawEqualsCString_(IoObject *self, const char *s);
IOVM_API double IoSeq_rawAsDoubleFromHex(IoObject *self);
IOVM_API double IoSeq_rawAsDoubleFromOctal(IoObject *self);

#include "IoSeq_immutable.h"
#include "IoSeq_mutable.h"
#include "IoSeq_inline.h"

#ifdef __cplusplus
}
#endif
#endif
