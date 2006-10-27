/*
 docCopyright("Steve Dekorte", 2002)
 docLicense("BSD revised")
 */

#include "IoState.h"
#include "IoObject.h"
#include "IoCoroutine.h"
#include "IoSeq.h"

void IoState_fatalError_(IoState *self, char *error)
{
	fputs(error, stderr);
	fputs("\n", stderr);
	exit(-1);
}

void IoState_error_(IoState *self, IoMessage *m, const char *format, ...)
{
	IoSymbol *description;
	
	va_list ap;
	va_start(ap, format);
	description = IoState_symbolWithByteArray_copy_(self, ByteArray_newWithVargs_(format, ap), 0);
	va_end(ap);
	
	/*
	fputs("\nIoState_error_: ", stderr); 
	fputs(CSTRING(description), stderr); 
	fputs("\n\n", stderr); 
	*/
	
	{
		IoCoroutine *coroutine = IoState_currentCoroutine(self);
		IoCoroutine_raiseError(coroutine, description, m);
	}
}

