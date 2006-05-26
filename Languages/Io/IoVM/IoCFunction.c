/*#io
getSlot("CFunction") ioDoc(
                docCopyright("Steve Dekorte", 2002)
                docLicense("BSD revised")
                docDescription("A container for a pointer to a C function binding. CFunction's can only be defined from the C side and act like blocks in that when placed in a slot, are called when the slot is activated. The for, if, while and clone methods of the Lobby are examples of CFunctions. CFunctions are useful for implementing methods that require the speed of C or binding to a C library.")
			 docCategory("Core")
                */

#include "IoCFunction.h"

#include "IoState.h"
#include "IoNumber.h"
#include <stddef.h>

#define DATA(self) ((IoCFunctionData *)IoObject_dataPointer(self))

IoTag *IoCFunction_tag(void *state)
{
	IoTag *tag = IoTag_newWithName_("CFunction");
	tag->state = state;
	tag->cloneFunc = (TagCloneFunc *)IoCFunction_rawClone;
	tag->markFunc  = (TagMarkFunc *)IoCFunction_mark;
	tag->activateFunc = (TagActivateFunc *)IoCFunction_activate;
	tag->freeFunc = (TagFreeFunc *)IoCFunction_free;
	return tag;
}

IoCFunction *IoCFunction_proto(void *state)
{
	IoObject *self = IoObject_new(state);
	self->tag = IoCFunction_tag(state);
	
	IoObject_setDataPointer_(self, calloc(1, sizeof(IoCFunctionData)));
	DATA(self)->func = IoObject_self;
	IoState_registerProtoWithFunc_((IoState *)state, self, IoCFunction_proto);
	return self;
}

void IoCFunction_protoFinish(void *state)
{
	IoMethodTable methodTable[] = {
	{"id", IoCFunction_id},
	{"==", IoCFunction_equals},
	{"performOn", IoFunction_performOn},
	{"uniqueName", IoCFunction_uniqueName},
	{"typeName", IoCFunction_typeName},
	{NULL, NULL},
	};
	
	IoObject *self = IoState_protoWithInitFunction_((IoState *)state, IoCFunction_proto);
	
	IoObject_addMethodTable_(self, methodTable);
}

IoCFunction *IoCFunction_rawClone(IoCFunction *proto)
{
	IoObject *self = IoObject_rawClonePrimitive(proto);
	IoObject_setDataPointer_(self, cpalloc(DATA(proto), sizeof(IoCFunctionData)));
	return self;
}

void IoCFunction_mark(IoCFunction *self)
{
	if (DATA(self)->uniqueName) 
	{ 
		IoObject_shouldMark(DATA(self)->uniqueName); 
	}
}

void IoCFunction_free(IoCFunction *self)
{
	/*
	printf("free ");
	IoCFunction_print(self);
	{
		IoObject *proto = IoState_protoWithName_(IOSTATE, "Object");
		IoObject *v = IoObject_rawGetSlot_(proto, DATA(self)->uniqueName);
	}
	*/
	free(IoObject_dataPointer(self));
}

void IoCFunction_print(IoCFunction *self)
{
	IoCFunctionData *data = DATA(self);
	
	printf("CFunction_%p", self);
	printf(" %p", (data->func));
	printf(" %s", data->typeTag ? data->typeTag->name : "?");
	if (data->uniqueName) printf(" %s", CSTRING(data->uniqueName));
	printf("\n");
}

IoCFunction *IoCFunction_newWithFunctionPointer_tag_name_(void *state, 
											   IoUserFunction *func, 
											   IoTag *typeTag, 
											   const char *funcName)
{
	IoCFunction *proto = IoState_protoWithInitFunction_((IoState *)state, IoCFunction_proto);
	IoCFunction *self = IOCLONE(proto);
	DATA(self)->typeTag = typeTag;
	DATA(self)->func = func;
	DATA(self)->uniqueName = IoState_symbolWithCString_((IoState *)state, funcName); 
	return self;
}

IoObject *IoCFunction_id(IoCFunction *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("id", "Returns a number containing a unique id for the receiver's internal C function. ")
	*/
	
	return IONUMBER(((ptrdiff_t)self)); 
}

IoObject *IoCFunction_uniqueName(IoCFunction *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("uniqueName", "Returns the name given to the CFunction.")
	*/
	
	if (DATA(self)->uniqueName) 
	{ 
		return DATA(self)->uniqueName; 
	}
	
	return IONIL(self);
}

IoObject *IoCFunction_typeName(IoCFunction *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("typeName", "Returns the owning type of the CFunction or nil if the CFunction can be called on any object.")
	*/
	
	if (DATA(self)->typeTag) 
	{ 
		return IOSYMBOL(IoTag_name(DATA(self)->typeTag)); 
	}
	
	return IONIL(self);
}

IoObject *IoCFunction_equals(IoCFunction *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("==(anObject)", "Returns self if the argument is a CFunction with the same internal C function pointer. ")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	
	return IOBOOL(self, ISCFUNCTION(v) && (DATA(self)->func == DATA(v)->func));
}

IoObject *IoCFunction_activate(IoCFunction *self, IoObject *target, IoObject *locals, IoMessage *m, IoObject *slotContext)
{
	IoCFunctionData *selfData = DATA(self);
	IoTag *t = selfData->typeTag;
	//IoObject_waitOnFutureIfNeeded(target); future forward will already deal with this? 
	IoObject *result;
	
	if (t && t != target->tag) // eliminate t check by matching Object tag?
	{
		char *a = (char *)IoTag_name(t);
		char *b = (char *)IoTag_name(target->tag);
		IoState_error_(IOSTATE, m, "CFunction defined for type %s but called on type %s", a, b);
	}
	
	//IoState_pushRetainPool(state);
	result = (*(IoUserFunction *)(selfData->func))(target, locals, m);
	//IoState_popRetainPoolExceptFor_(state, result);
	return result;
}

IoObject *IoFunction_performOn(IoCFunction *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("performOn(target, blockLocals, optionalMessage, optionalContext)", "Activates the CFunctions with the supplied settings.")
	*/
	
	IoObject *bTarget = IoMessage_locals_valueArgAt_(m, locals, 0);
	IoObject *bLocals = locals;
	IoObject *bMessage = m;
	IoObject *bContext = bTarget;
	int argCount = IoMessage_argCount(m);
	
	if (argCount > 1) 
	{
		bLocals = IoMessage_locals_valueArgAt_(m, locals, 1); 
	}
	
	if (argCount > 2) 
	{
		bMessage = IoMessage_locals_valueArgAt_(m, locals, 2); 
	}
	
	if (argCount > 3) 
	{
		bContext = IoMessage_locals_valueArgAt_(m, locals, 3); 
	}
	
	return IoCFunction_activate(self, bTarget, bLocals, bMessage, bContext);
}

