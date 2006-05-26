#include "IoState.h"
#include "IoObject.h"

void IoState_show(IoState *self)
{
	printf("--- state ----------------------------------\n");
	printf("State:\n");
	/*
	 printf("black:\n");
	 IoObjectGroup_show(self->blackGroup);
	 printf("\n");
	 
	 printf("gray:\n");
	 IoObjectGroup_show(self->grayGroup);  
	 printf("\n");
	 
	 printf("white:\n");
	 IoObjectGroup_show(self->whiteGroup);    
	 printf("\n");
	 */
	printf("stacks:\n");
	printf("\n");  
}

IoObject *IoState_replacePerformFunc_with_(IoState *self, 
								   TagPerformFunc *oldFunc, 
								   TagPerformFunc *newFunc)
{
	IoObject *proto = Hash_firstValue(self->primitives);
	
	while (proto)
	{
		if (proto->tag->performFunc == oldFunc)
		{
			proto->tag->performFunc = newFunc;
		}
		
		proto = Hash_nextValue(self->primitives);
	}
	
	return 0x0;
}

void IoState_debuggingOn(IoState *self)
{
	IoState_replacePerformFunc_with_(self, 
							   (TagPerformFunc *)IoObject_perform, 
							   (TagPerformFunc *)IoObject_performWithDebugger);
}

void IoState_debuggingOff(IoState *self)
{
	IoState_replacePerformFunc_with_(self, 
							   (TagPerformFunc *)IoObject_performWithDebugger, 
							   (TagPerformFunc *)IoObject_perform);
}

int IoState_hasDebuggingCoroutine(IoState *self)
{
	return 1; // hack awaiting decision on how to change this
}

void IoState_updateDebuggingMode(IoState *self)
{
	if (IoState_hasDebuggingCoroutine(self))
	{
		IoState_debuggingOn(self);
	}
	else
	{
		IoState_debuggingOff(self);
	}
}
