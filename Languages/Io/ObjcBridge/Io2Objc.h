/*   Copyright (c) 2003, Steve Dekorte
docLicense("BSD revised")
 *
 *   An Io proxy to an Objective-C object or class
 */

#ifndef IOOBJECTIVEC_DEFINED
#define IOOBJECTIVEC_DEFINED 1

#include "IoState.h"
#include "IoObject.h"
#include "IoNumber.h"
#include "List.h"
#include <ctype.h>

#ifdef GNUSTEP
  #include <Foundation/Foundation.h>
#else
  #import <Foundation/Foundation.h>
#endif

#include "IoObject.h"
#include "IoObject.h"
#include "IoObjcBridge.h"

#define ISIO2OBJC(self) IoObject_hasCloneFunc_(self, (TagCloneFunc *)Io2Objc_rawClone)

typedef IoObject Io2Objc;

typedef struct
{
  IoObjcBridge *bridge;
  id object; /* object object that this instance is talking to */
  unsigned char *returnBuffer;
  int returnBufferSize;
} Io2ObjcData;

Io2Objc *Io2Objc_rawClone(Io2Objc *self);
Io2Objc *Io2Objc_proto(void *state);
Io2Objc *Io2Objc_new(void *state);

void Io2Objc_free(Io2Objc *self);
void Io2Objc_nullObjcBridge(Io2Objc *self);

void Io2Objc_mark(Io2Objc *self);
void Io2Objc_setBridge(Io2Objc *self, void *bridge);
void Io2Objc_setObject(Io2Objc *self, void *object);
void *Io2Objc_object(Io2Objc *self);

/* ----------------------------------------------------------------- */
IoObject *Io2Objc_perform(Io2Objc *self, IoObject *locals, IoMessage *m);

#endif

