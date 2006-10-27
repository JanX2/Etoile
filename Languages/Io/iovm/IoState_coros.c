/*
 docCopyright("Steve Dekorte", 2002)
 docLicense("BSD revised")
 */

#include "IoState.h"
#include "IoObject.h"

IoObject *IoState_currentCoroutine(IoState *self) 
{ 
	return self->currentCoroutine; 
}

void IoState_setCurrentCoroutine_(IoState *self, IoObject *coroutine) 
{ 
	self->currentCoroutine = coroutine; 
	self->currentIoStack = IoCoroutine_rawIoStack(coroutine);
	Collector_setMarkBeforeSweepValue_(self->collector, coroutine);
}

void IoState_yield(IoState *self)
{
	printf("IoState_yield needs to be re-implemented\n");
	exit(-1);
}



