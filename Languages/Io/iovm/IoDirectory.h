/*
docCopyright("Steve Dekorte", 2002)
*/

#ifndef IODIRECTORY_DEFINED
#define IODIRECTORY_DEFINED 1

#include "IoVMApi.h"

#include "IoObject.h"
#include "IoSeq.h"

#define ISDIRECTORY(self) IoObject_hasCloneFunc_(self, (TagCloneFunc *)IoDirectory_rawClone)

typedef IoObject IoDirectory;

typedef struct
{
    IoSymbol *path;
} IoDirectoryData;

IOVM_API IoDirectory *IoDirectory_rawClone(IoObject *self);
IOVM_API IoDirectory *IoDirectory_proto(void *state);
IOVM_API IoDirectory *IoDirectory_new(void *state);
IOVM_API IoDirectory *IoDirectory_newWithPath_(void *state, IoSymbol *path);
IOVM_API IoDirectory *IoDirectory_cloneWithPath_(IoObject *self, IoSymbol *path);

IOVM_API void IoDirectory_free(IoObject *self);
IOVM_API void IoDirectory_mark(IoObject *self);

// ----------------------------------------------------------- 

IOVM_API IoObject *IoDirectory_path(IoObject *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoDirectory_setPath(IoObject *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoDirectory_name(IoObject *self, IoObject *locals, IoMessage *m);

IOVM_API IoObject *IoDirectory_at(IoObject *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoDirectory_size(IoObject *self, IoObject *locals, IoMessage *m);

IOVM_API IoObject *IoDirectory_exists(IoObject *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoDirectory_items(IoObject *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoDirectory_create(IoObject *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoDirectory_createSubdirectory(IoObject *self, IoObject *locals, IoMessage *m);

IOVM_API ByteArray *IoDirectory_CurrentWorkingDirectoryAsByteArray(void);
IOVM_API int IoDirectory_SetCurrentWorkingDirectory(const char *path);

IOVM_API IoObject *IoDirectory_currentWorkingDirectory(IoObject *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoDirectory_setCurrentWorkingDirectory(IoObject *self, IoObject *locals, IoMessage *m);

#endif
