
#include "IoSeq.h"

void IoSeq_rawPrint(IoSeq *self);
void IoSeq_addImmutableMethods(IoSeq *self);

IoObject *IoSeq_with(IoSeq *self, IoObject *locals, IoMessage *m);

// conversion

IoObject *IoSeq_asBinaryNumber(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_asSymbol(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_isMutable(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_isSymbol(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_asNumber(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_whiteSpaceStrings(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_print(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_linePrint(IoObject *self, IoObject *locals, IoMessage *m);

// access

IoObject *IoSeq_size(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_at(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_slice(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_between(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_asNumber(IoSeq *self, IoObject *locals, IoMessage *m);

// find

IoObject *IoSeq_findSeq(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_reverseFindSeq(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_beginsWithSeq(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_endsWithSeq(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_join(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_split(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_contains(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_containsSeq(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_containsAnyCaseSeq(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_isLowercase(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_isUppercase(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_isEqualAnyCase(IoSeq *self, IoObject *locals, IoMessage *m);

// split 

IoObject *IoSeq_split(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_splitAt(IoSeq *self, IoObject *locals, IoMessage *m);

// data types

IoObject *IoSeq_int32At(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_uint32At(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_float32At(IoSeq *self, IoObject *locals, IoMessage *m);

// base

IoObject *IoSeq_fromBase(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_toBase(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_foreach(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_asMessage(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_cloneAppendSeq(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_asMutable(IoSeq *self, IoObject *locals, IoMessage *m);

// case 

IoObject *IoSeq_asUppercase(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_asLowercase(IoSeq *self, IoObject *locals, IoMessage *m);

// path 

IoObject *IoSeq_lastPathComponent(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_pathExtension(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_fileName(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_cloneAppendPath(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_pathComponent(IoObject *self, IoObject *locals, IoMessage *m);


IoObject *IoSeq_beforeSeq(IoSeq *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_afterSeq(IoSeq *self, IoObject *locals, IoMessage *m);

IoObject *IoSeq_asCapitalized(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoSeq_occurancesOfSeq(IoObject *self, IoObject *locals, IoMessage *m);
