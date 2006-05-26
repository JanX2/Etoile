/*#io
Call ioDoc(
            docCopyright("Steve Dekorte", 2002)
            docLicense("BSD revised")
            docDescription("Call stores slots related to activation.")
		  docCategory("Core")
*/

#include "IoCall.h"
#include "IoState.h"
#include "IoObject.h"

#define DATA(self) ((IoCallData *)IoObject_dataPointer(self))

IoTag *IoCall_tag(void *state)
{
	IoTag *tag = IoTag_newWithName_("Call");
	tag->state = state;
	tag->cloneFunc = (TagCloneFunc *)IoCall_rawClone;
	tag->markFunc  = (TagMarkFunc *)IoCall_mark;
	tag->freeFunc  = (TagFreeFunc *)IoCall_free;
	tag->writeToStoreOnStreamFunc  = (TagWriteToStoreOnStreamFunc *)IoCall_writeToStore_stream_;
	tag->readFromStoreOnStreamFunc = (TagReadFromStoreOnStreamFunc *)IoCall_readFromStore_stream_;
	return tag;
}
 
void IoCall_writeToStore_stream_(IoCall *self, IoStore *store, BStream *stream)
{
}

void IoCall_readFromStore_stream_(IoCall *self, IoStore *store, BStream *stream)
{
}

void IoCall_initSlots(IoCall *self)
{
	IoObject *ioNil = IOSTATE->ioNil;
	DATA(self)->sender      = ioNil;
	DATA(self)->message     = ioNil;
	DATA(self)->slotContext = ioNil;
	DATA(self)->target      = ioNil;
	DATA(self)->activated   = ioNil;
}

IoCall *IoCall_proto(void *vState)
{
	IoState *state = (IoState *)vState;
	
	IoMethodTable methodTable[] = {
	{"sender",      IoCall_sender},
	{"message",     IoCall_message},
	{"slotContext", IoCall_slotContext},
	{"target",      IoCall_target},
	{"activated",   IoCall_activated},
	{"evalArgAt",   IoCall_evalArgAt},
	{"argAt",       IoCall_argAt},
	{NULL, NULL},
	};
	
	IoObject *self = IoObject_new(state);
	
	IoObject_setDataPointer_(self, calloc(1, sizeof(IoCallData)));
	self->tag = IoCall_tag(state);
	IoCall_initSlots(self);
	
	IoState_registerProtoWithFunc_((IoState *)state, self, IoCall_proto);
	
	IoObject_addMethodTable_(self, methodTable);
	return self;
}

IoCall *IoCall_rawClone(IoCall *proto)
{
	IoObject *self = IoObject_rawClonePrimitive(proto);
	IoObject_setDataPointer_(self, cpalloc(IoObject_dataPointer(proto), sizeof(IoCallData)));
	IoCall_initSlots(self);
	return self;
}

IoCall *IoCall_new(IoState *state)
{
	IoObject *proto = IoState_protoWithInitFunction_((IoState *)state, IoCall_proto);
	return IOCLONE(proto);
}

IoCall *IoCall_with(void *state, 
				 IoObject *sender,
				 IoObject *target,
				 IoObject *message,
				 IoObject *slotContext,
				 IoObject *activated)
{
	IoCall *self = IoCall_new(state);
	DATA(self)->sender      = IOREF(sender);
	DATA(self)->target      = IOREF(target);
	DATA(self)->message     = IOREF(message);
	DATA(self)->slotContext = IOREF(slotContext);	
	DATA(self)->activated   = IOREF(activated);
	return self;
}

void IoCall_mark(IoCall *self)
{ 
	IoCallData *d = DATA(self);

	IoObject_shouldMarkIfNonNull(d->sender);
	IoObject_shouldMarkIfNonNull(d->target);
	IoObject_shouldMarkIfNonNull(d->message);
	IoObject_shouldMarkIfNonNull(d->slotContext);
	IoObject_shouldMarkIfNonNull(d->activated);
}

void IoCall_free(IoCall *self)
{
	free(IoObject_dataPointer(self)); 
}

IoObject *IoCall_sender(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("sender", "Returns the sender value.")
	*/
	return DATA(self)->sender;
}

IoObject *IoCall_message(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("message", "Returns the message value.")
	*/
	return DATA(self)->message;
}

IoObject *IoCall_target(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("target", "Returns the target value.")
	*/
	return DATA(self)->target;
}

IoObject *IoCall_slotContext(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("slotContext", "Returns the slotContext value.")
	*/
	return DATA(self)->slotContext;
}

IoObject *IoCall_activated(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("activated", "Returns the activated value.")
	*/
	return DATA(self)->activated;
}

IoObject *IoCall_evalArgAt(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("evalArgAt(argNumber)", "Evaluates the specified argument of the Call's message in the context of it's sender.")
	*/
	int n = IoMessage_locals_intArgAt_(m, locals, 0);
	IoCallData *data = DATA(self);
	return IoMessage_locals_valueArgAt_(data->message, data->sender, n);
}

IoObject *IoCall_argAt(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("argAt(argNumber)", "Returns the message's argNumber arg. Shorthand for same as call message argAt(argNumber).")
	*/
	return IoMessage_argAt(DATA(self)->message, locals, m);
}
