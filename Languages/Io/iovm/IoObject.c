/*#io
Object ioDoc(
			 docCopyright("Steve Dekorte", 2002)
			 docLicense("BSD revised")
			 docObject("Object")
			 docInclude("_ioCode/Object.io")
			 docDescription("""An Object is a key/value dictionary with string keys and values of any type. The prototype Object contains a clone slot that is a CFuntion that creates new objects. When cloned, an Object will call it's init slot (with no arguments).

<p><b>Important note:</b></p>
<p>The data structure used for objects is optimized for objects with relatively few slots (less than 100). Objects become very memory inefficient (exponentially so) when they have a large number of slots. Objects should not be used as large hash tables or lists. Use a Hash or List primitive instead.</p>""")
		   docCategory("Core")
			 */

#include "IoState.h"
#define IOOBJECT_C
#include "IoObject.h"
#undef IOOBJECT_C 
#include "IoCoroutine.h"
#include "IoTag.h"
#include "IoCFunction.h"
#include "IoSeq.h"
#include "IoNumber.h"
#include "IoMessage.h"
#include "IoMessage_parser.h"
#include "IoCFunction.h"
#include "IoBlock.h"
#include "IoList.h"
#include "IoObject.h"
#include "IoFile.h"
#include "IoSeq.h"
#include <string.h>
#include <stddef.h>

IoObject *IoObject_activateFunc(IoObject *self, 
								IoObject *target, 
								IoObject *locals, 
								IoMessage *m, 
								IoObject *slotContext);

IoTag *IoObject_tag(void *state)
{
	IoTag *tag = IoTag_newWithName_("Object");
	tag->state = state;
	tag->cloneFunc = (TagCloneFunc *)IoObject_rawClone;
	tag->activateFunc = (TagActivateFunc *)0x0; // IoObject_activateFunc;
	return tag;
}

IoObject *IoObject_proto(void *state)
{
	IoObject *self = calloc(1, sizeof(IoObject));
	
	IoObject_setupProtos(self);
	self->slots = PHash_new();
	self->ownsSlots = 1;
	
	self->tag = IoObject_tag(state);
	self->state = state;
	IoObject_setDataPointer_(self, 0x0);
	IoState_registerProtoWithFunc_((IoState *)state, self, IoObject_proto);
		
	return self;
}

IoObject *IoObject_protoFinish(void *state)
{	
	IoMethodTable methodTable[] = { 
	{"clone", IoObject_clone},
	{"cloneWithoutInit", IoObject_cloneWithoutInit},
	{"shallowCopy", IoObject_shallowCopy},
	{"duplicate", IoObject_duplicate},
	//{"print", IoObject_protoPrint},
	{"write", IoObject_protoWrite},
	{"writeln", IoObject_protoWriteLn},
	{"type", IoObject_type},
		
	// logic 
				
	{"compare", IoObject_protoCompare},
	{"<", IoObject_isLessThan_},
	{">", IoObject_isGreaterThan_},
	{">=", IoObject_isGreaterThanOrEqualTo_},
	{"<=", IoObject_isLessThanOrEqualTo_},
		
	// comparison 
		
	{"isIdenticalTo", IoObject_isIdenticalTo},
	{"==", IoObject_equals},
	{"!=", IoObject_notEquals},
		
	// introspection 
		
	//{"self", IoObject_self},
	{"setSlot", IoObject_protoSet_to_},
	{"setSlotWithType", IoObject_protoSetSlotWithType},
	{"updateSlot", IoObject_protoUpdateSlot_to_},
	{"getSlot", IoObject_protoGetSlot_},
	{"getLocalSlot", IoObject_protoGetLocalSlot_},
	{"hasLocalSlot", IoObject_protoHasLocalSlot},
	{"hasProto", IoObject_protoHasProto_},
	{"removeSlot", IoObject_protoRemoveSlot},
	{"slotNames", IoObject_protoSlotNames},
		
	// method invocation
		
	{"perform", IoObject_protoPerform},
	{"performWithArgList", IoObject_protoPerformWithArgList},
	{"ancestorWithSlot", IoObject_ancestorWithSlot},
	{"contextWithSlot", IoObject_contextWithSlot},
		
	// control 
		
	{"block", IoObject_block},
	{"method", IoBlock_method},
	{"for", IoObject_for},
	{"if", IoObject_if},
	{"", IoObject_evalArg},
	{"evalArg", IoObject_evalArg},
	{"evalArgAndReturnSelf", IoObject_evalArgAndReturnSelf},
	{"evalArgAndReturnNil", IoObject_evalArgAndReturnNil},
		
	{"return", IoObject_return},
	{"returnIfNonNil", IoObject_returnIfNonNil},
	{"loop", IoObject_loop},
	{"while", IoObject_while},
	{"break", IoObject_break},
	{"continue", IoObject_continue},
		
    // utility 
		
	{"print", IoObject_lobbyPrint},
	{"do", IoObject_do},
	{"message", IoObject_message},
	{"doMessage", IoObject_doMessage},
	{"doString", IoObject_doString},
	{"doFile", IoObject_doFile},
	//{"unpack", IoObject_unpack},
		
     // reflection
		
	{"uniqueId", IoObject_uniqueId},
		
    // memory utilities
		
    //{"memorySize", IoObject_memorySizeMethod},
    //{"compact", IoObject_compactMethod},
		
	{"init", IoObject_self},
		
    // enumeration 
		
	{"foreachSlot", IoObject_foreachSlot},
	{"-", IoObject_subtract},
				
	{"thisContext", IoObject_self},
	{"thisLocalContext", IoObject_locals},
		
    // protos
		
	{"setProto", IoObject_setProto},
	{"setProtos", IoObject_setProtos},
	{"appendProto", IoObject_appendProto},
	{"prependProto", IoObject_prependProto},
	{"removeProto", IoObject_removeProto},
	{"removeAllProtos", IoObject_removeAllProtos},
	{"protos", IoObject_protos},
	{"proto", IoObject_objectProto},
	//{"tailCall", IoObject_tailCall},
	{"setIsActivatable", IoObject_setIsActivatable},
	{"isActivatable", IoObject_isActivatable},
	{"argIsActivationRecord", IoObject_argIsActivationRecord},
	{"argIsCall", IoObject_argIsCall},
		
	{0x0, 0x0},
	};
	
	IoObject *self = IoState_protoWithInitFunction_((IoState *)state, IoObject_proto);
	
	IoObject_addMethodTable_(self, methodTable);
	return self;
}

#include <assert.h>

IoObject *IoObject_localsProto(void *state)
{
	IoObject *self = IoObject_new(state);
	IoObject *proto = IoObject_firstProto(self);
		
	IoObject_createSlotsIfNeeded(self);
	PHash_copy_(self->slots, proto->slots);

	IoObject_rawRemoveAllProtos(self);
	
	IoObject_removeSlot_(self, IOSYMBOL("delegate")); 
	IoObject_addMethod_(self, IOSYMBOL("forward"), IoObject_localsForward);
	IoObject_addMethod_(self, IOSYMBOL("setSlot"), IoObject_protoSet_to_);
	IoObject_addMethod_(self, IOSYMBOL("setSlotWithType"), IoObject_protoSetSlotWithType);
	IoObject_addMethod_(self, IOSYMBOL("updateSlot"), IoObject_localsUpdateSlot);
	return self;
}

IoObject *IoObject_addMethod_(IoObject *self, IoSymbol *slotName, IoMethodFunc *fp)
{
	IoTag *t = self->tag;
	IoObject *proto = IoState_protoWithInitFunction_(IOSTATE, IoObject_proto);
	IoCFunction *f;
	
	if (t == proto->tag)
	{
		t = 0x0;
	}
	
	f = IoCFunction_newWithFunctionPointer_tag_name_(IOSTATE, (IoUserFunction *)fp, t, CSTRING(slotName));
	IoObject_setSlot_to_(self, slotName, f);
	return f;
}

void IoObject_addMethodTable_(IoObject *self, IoMethodTable *methodTable)
{
	IoMethodTable *entry = methodTable;
	
	while (entry->name) 
	{
		IoObject_addMethod_(self, IOSYMBOL(entry->name), entry->func);
		entry ++;
	}
}

IoObject *IoObject_new(void *state)
{
	IoObject *proto = IoState_protoWithInitFunction_((IoState *)state, IoObject_proto);
	return IOCLONE(proto);
}

IoObject *IoObject_justClone(IoObject *self)
{ 
	return (self->tag->cloneFunc)(self); 
}

void IoObject_createSlots(IoObject *self)
{
	self->slots = PHash_new();
	self->ownsSlots = 1;
}

inline void IoObject_freeData(IoObject *self) 
{
	//if (!self->doesNotOwnData)
	{
		TagFreeFunc *func = self->tag->freeFunc;
		
		if (func) 
		{ 
			(*func)(self); 
		}
		else if (IoObject_dataPointer(self)) 
		{ 
			free(IoObject_dataPointer(self)); 
		}
	}
	
	IoObject_setDataPointer_(self, 0x0);
}

#define IOOBJECT_RECYCLE

#ifdef IOOBJECT_RECYCLE

/*static int recycleHighPoint = 0;*/

void IoObject_clearMark(IoObject *self)
{
	memset(&(self->marker), 0x0, sizeof(CollectorMarker));
	
	self->hasDoneLookup = 0;
	//self->ownsSlots = 0;
	self->isSymbol = 0;
	
	self->isDirty = 0;
	//self->doesNotOwnData = 0;
	self->isLocals = 0;
	self->isActivatable = 0;
}

inline IoObject *IoObject_alloc(IoObject *self)
{
	IoObject *pchild = List_pop(IOSTATE->recycledObjects);
	IoObject *child = pchild;
	
	if (!child) 
	{
		child = (IoObject *)calloc(1, sizeof(IoObject));
		IoObject_setupProtos(child);
	}

	IoObject_clearMark(child);
	
	child->state = self->tag->state;
	return child;
}

inline void IoObject_unalloc(IoObject *self)
{
	if (IOSTATE->recycledObjects) 
	{ 
		self->isSymbol = 0;
		/*printf("recycling %p\n", (void *)self);*/
		List_append_(IOSTATE->recycledObjects, self);
		/*
		 if (List_size(IOSTATE->recycledObjects) > recycleHighPoint)
		 { 
			 recycleHighPoint = List_size(IOSTATE->recycledObjects); 
			 printf("recycleHighPoint %i\n", recycleHighPoint);
		 }
		 */
	}
	else
	{ 
		IoObject_dealloc(self); 
	}
}

#else

inline IoObject *IoObject_alloc(IoObject *self)
{ 
	IoObject *child = calloc(1, sizeof(IoObject));
	IoObject_setupProtos(self);
	child->state = self->tag->state;
	return child;
}

#endif

inline void IoObject_setProtoTo_(IoObject *self, IoObject *proto)
{
	IoObject_rawRemoveAllProtos(self);
	IoObject_rawSetProto_(self, proto);
	
	if (!self->slots)
	{
		self->slots = proto->slots;
		self->ownsSlots = 0; // should be redundant 
	}
}

IoObject *IoObject_rawClone(IoObject *proto)
{
	IoObject *self = IoObject_alloc(proto);
	self->tag = proto->tag;
	IoObject_setProtoTo_(self, proto);
	IoObject_setDataPointer_(self, IoObject_dataPointer(proto)); // is this right?
	self->isDirty = 1;
	return self;
}

IoObject *IoObject_rawClonePrimitive(IoObject *proto)
{
	IoObject *self = IoObject_alloc(proto);
	self->tag = proto->tag;
	IoObject_setProtoTo_(self, proto);
	IoObject_setDataPointer_(self, 0x0);
	self->isDirty = 1;
	return self;
}

// protos --------------------------------------------- 

void IoObject_rawPrintProtos(IoObject *self)
{
	IoObject **proto = self->protos;
	int count = 0;
	
	while (*proto)
	{
		printf("%i : %p\n", count, (void *)(*proto));
		proto ++;
		count ++;
	}
	
	printf("\n");
}

void IoObject_setupProtos(IoObject *self)
{
	self->protos = (IoObject **)calloc(2, sizeof(IoObject *));
}

int IoObject_hasProtos(IoObject *self)
{
	return (self->protos[0] != 0x0);
}

int IoObject_rawProtosCount(IoObject *self)
{
	IoObject **proto = self->protos;
	int count = 0;
	
	while (*proto)
	{
		proto ++;
		count ++;
	}
	
	return count;
}

void IoObject_rawAppendProto_(IoObject *self, IoObject *p)
{
	int count = IoObject_rawProtosCount(self);
	
	self->protos = realloc(self->protos, (count + 2) * sizeof(IoObject *));
	self->protos[count] = IOREF(p);
	self->protos[count + 1] = 0x0;
}

void IoObject_rawPrependProto_(IoObject *self, IoObject *p)
{
	int count = IoObject_rawProtosCount(self);
	int oldSize = (count + 1) * sizeof(IoObject *);
	int newSize = oldSize + sizeof(IoObject *);
		
	self->protos = realloc(self->protos, newSize);
	
	{
		void *src = self->protos;
		void *dst = self->protos + 1;
		memmove(dst, src, oldSize);
	}
	
	self->protos[0] = IOREF(p);
}

void IoObject_rawRemoveProto_(IoObject *self, IoObject *p)
{
    IoObject **proto = self->protos;
    int count = IoObject_rawProtosCount(self);
    int index = 0;

    while (*proto)
    {
        if (*proto == p)
        {
            memcpy(proto, proto + 1, (count - index) * sizeof(IoObject *));
        }
        else
        {	
            proto ++;
        }
	    
        index ++;
    }
}

#include <assert.h>

/*
void IoObject_testProtosCode(IoObject *self)
{
	IoObject *o1 = (IoObject *)0x1;
	IoObject *o2 = (IoObject *)0x2;
	int c;
	
	IoObject_rawRemoveAllProtos(self);
	c = IoObject_rawProtosCount(self);
	assert(c == 0);
	
	IoObject_rawAppendProto_(self, o1);
	assert(IoObject_rawProtoAt_(self, 0) == o1);
	assert(IoObject_rawProtoAt_(self, 1) == 0x0);
	assert(IoObject_rawProtosCount(self) == 1);
	
	IoObject_rawPrependProto_(self, (IoObject *)0x2);
	assert(IoObject_rawProtosCount(self) == 2);
	assert(IoObject_rawProtoAt_(self, 0) == o2);
	assert(IoObject_rawProtoAt_(self, 1) == o1);
	assert(IoObject_rawProtoAt_(self, 2) == 0x0);
	
	IoObject_rawRemoveAllProtos(self);
	c = IoObject_rawProtosCount(self);
	assert(c == 0);    
}
*/

void IoObject_rawSetProto_(IoObject *self, IoObject *proto)
{
	self->protos[0] = IOREF(proto);
} 

IoObject *IoObject_objectProto(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("proto", "Same as; method(self protos first)")
	*/
	
	IoObject *proto = self->protos[0];
	
	return proto ? proto : IONIL(self);
} 

IoObject *IoObject_setProto(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("setProto(anObject)", 
			"Sets the first proto of the receiver to anObject, replacing the 
current one, if any. Returns self.")
	*/
	
	IoObject *proto = IoMessage_locals_valueArgAt_(m, locals, 0);
	
	IoObject_rawSetProto_(self, proto);    
	return self;
} 

IoObject *IoObject_appendProto(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("appendProto(anObject)", 
			"Appends anObject to the receiver's proto list. Returns self.")
	*/
	
	IoObject *proto = IoMessage_locals_valueArgAt_(m, locals, 0);
	IoObject_rawAppendProto_(self, proto);
	return self;
}

IoObject *IoObject_prependProto(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("prependProto(anObject)", 
			"Prepends anObject to the receiver's proto list. Returns self.")
	*/
	
	IoObject *proto = IoMessage_locals_valueArgAt_(m, locals, 0);
	IoObject_rawPrependProto_(self, proto);
	return self;
} 

IoObject *IoObject_removeProto(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("removeProto(anObject)", 
			"Remove's anObject from the receiver's proto list if it 
is present. Returns self.")
	*/
	
	IoObject *proto = IoMessage_locals_valueArgAt_(m, locals, 0);
	IoObject_rawRemoveProto_(self, proto);
	return self;
} 

IoObject *IoObject_removeAllProtos(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("removeAllProtos", 
			"Remove's all of the receiver's protos. Returns self. ")
	*/
	
	IoObject_rawRemoveAllProtos(self);
	return self;
}

IoObject *IoObject_setProtos(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("setProtos(aList)", 
			"Replaces the receiver's protos with a copy of aList. Returns self.") 
	*/
	
	IoList *ioList = IoMessage_locals_listArgAt_(m, locals, 0);
	List *list = IoList_rawList(ioList);
	
	IoObject_rawRemoveAllProtos(self);
	List_target_do_(list, self, (ListDoWithCallback *)IoObject_rawAppendProto_);
	
	return self;
}


IoObject *IoObject_protos(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("protos", "Returns a copy of the receiver's protos list.")
	*/
	
	IoList *ioList = IoList_new(IOSTATE);
	List *list = IoList_rawList(ioList);
	IoObject **proto = self->protos;
	
	while (*proto)
	{
		List_append_(list, *proto);
		proto ++;
	}
	
	return ioList;
} 

// -------------------------------------------------------- 

inline void IoObject_freeSlots(IoObject *self) // prepare for free and possibly recycle 
{  
	if (self->ownsSlots) 
	{ 
		PHash_free(self->slots);
		self->slots = 0x0;
		self->ownsSlots = 0;
	}
	
	self->slots = 0x0;
}

/*
void IoObject_listenNotification(IoObject *self, void *notification) 
{
	self->tag->notificationFunc(self, notification);
}
*/

void IoObject_free(IoObject *self) // prepare for free and possibly recycle 
{  
	/*
	if (self->isLocals)
	{
		printf("free %p locals\n", (void *)self);
	}
	else
	{
		printf("free %p %s\n", (void *)self, IoObject_name(self));
	}
	*/
	
	if (self->listeners)
	{
		LIST_FOREACH(self->listeners, i, v, ((IoObject *)v)->tag->notificationFunc(v, 0x0));
	}
	
	self->isLocals = 0;
	
	IoObject_freeData(self);
	
	//self->tag = 0x0;
	IoObject_rawRemoveAllProtos(self);
	self->persistentId = 0;
	
#ifdef IOOBJECT_RECYCLE
	
	if (self->ownsSlots)
	{ 
		PHash_clean(self->slots); 
	}
	else 
	{ 
		self->slots = 0x0; 
	}
	
	IoObject_unalloc(self);
	
#else
	
	IoObject_dealloc(self);
	
#endif 
}

void IoObject_dealloc(IoObject *self) // really free it 
{ 
	if (self->ownsSlots) 
	{
		PHash_free(self->slots);
	}
	
	free(self->protos);
	memset(self, 0x0, sizeof(IoObject)); // temp 
	free(self);
}

// ---------------------------------------------------------------- 

IoObject *IoObject_protoCompare(IoObject *self, IoObject *locals, IoMessage *m) 
{
	/*#io
	docSlot("compare(anObject)", 
			"Returns a number containing the comparison value of the target with anObject.")
	*/
	IOASSERT(IoMessage_argCount(m), "compare requires argument");
	
	{
		IoSymbol *other = IoMessage_locals_valueArgAt_(m, locals, 0);
		return IONUMBER(IoObject_compare(self, other));
	}
}

// slot lookups with lookup loop detection 

unsigned int IoObject_rawHasProto_(IoObject *self, IoObject *p)
{ 
	if (self == p) 
	{
		return 1;
	}
	
	if (IoObject_hasDoneLookup(self)) 
	{
		return 0;
	}
	else
	{
		IoObject **proto = self->protos;
		
		IoObject_setHasDoneLookup_(self, 1);
		
		while (*proto) 
		{
			if (IoObject_rawHasProto_(*proto, p))
			{
				IoObject_setHasDoneLookup_(self, 0);
				return 1;
			}
			
			proto ++;
		}
		
		IoObject_setHasDoneLookup_(self, 0);
		return 0;
	}
}

IoObject *IoObject_protoHasProto_(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("hasProto(anObject)", 
			"Returns true if anObject is found in the proto path of the target, false otherwise.")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, IoObject_rawHasProto_(self, v));
}

// ------------------------------------------------------ 

IoObject *IoObject_getSlot_(IoObject *self, IoSymbol *slotName)
{ 
	IoObject *v = IoObject_rawGetSlot_(self, slotName);
	return v ? v : IONIL(self);
}

double IoObject_doubleGetSlot_(IoObject *self, IoSymbol *slotName)
{ 
	IoObject *v = IoObject_rawGetSlot_(self, slotName);
	
	if (!v)
	{
		IoState_error_(IOSTATE, 0x0, "missing slot %s in %s", 
					CSTRING(slotName), IoObject_name(self));
	}

	if (!ISNUMBER(v))
	{
		IoState_error_(IOSTATE, 0x0, "slot %s in %s must be a number, not a %s", 
					CSTRING(slotName), IoObject_name(self), IoObject_name(v));
	}
	
	return CNUMBER(v);
}

IoObject *IoObject_symbolGetSlot_(IoObject *self, IoSymbol *slotName)
{ 
	IoObject *v = IoObject_rawGetSlot_(self, slotName);
	
	if (!v)
	{
		IoState_error_(IOSTATE, 0x0, "missing slot %s in %s", 
					CSTRING(slotName), IoObject_name(self));
	}
	
	if (!ISSYMBOL(v))
	{
		IoState_error_(IOSTATE, 0x0, "slot %s in %s must be a symbol, not a %s", 
					CSTRING(slotName), IoObject_name(self), IoObject_name(v));
	}
	
	return v;
}

IoObject *IoObject_seqGetSlot_(IoObject *self, IoSymbol *slotName)
{ 
	IoObject *v = IoObject_rawGetSlot_(self, slotName);
	
	if (!v)
	{
		IoState_error_(IOSTATE, 0x0, "missing slot %s in %s", 
					CSTRING(slotName), IoObject_name(self));
	}
	
	if (!ISSEQ(v))
	{
		IoState_error_(IOSTATE, 0x0, "slot %s in %s must be a sequence, not a %s", 
					CSTRING(slotName), IoObject_name(self), IoObject_name(v));
	}
	
	return v;
}

IoObject *IoObject_activateFunc(IoObject *self, 
								IoObject *target, 
								IoObject *locals, 
								IoMessage *m,
								IoObject *slotContext)
{
	IoState *state = IOSTATE;
	
	if (self->isActivatable)
	{
		IoObject *context;
		IoObject *slotValue = IoObject_rawGetSlot_context_(self, state->activateSymbol, &context);
		
		if (slotValue) 
		{
			return IoObject_activate(slotValue, self, locals, m, context);
		}	
	}
	return self;
}

// ----------------------------------------------------------- 

void IoObject_setSlot_to_(IoObject *self, IoSymbol *slotName, IoObject *value)
{ 
	IoObject_inlineSetSlot_to_(self, slotName, value); 
}

void IoObject_removeSlot_(IoObject *self, IoSymbol *slotName)
{     
	IoObject_createSlotsIfNeeded(self);
	PHash_removeKey_(self->slots, slotName); 
}

IoObject *IoObject_rawGetSlot_target_(IoObject *self, IoSymbol *slotName, IoObject **target)
{
	IoObject *slotValue = IoObject_rawGetSlot_(self, slotName);
	
	if (!slotValue)
	{
		IoObject *selfDelegate = IoObject_rawGetSlot_(self, IOSTATE->selfSymbol);
		
		if (selfDelegate && selfDelegate != self) 
		{
			slotValue = IoObject_rawGetSlot_(selfDelegate, slotName);
			
			if (slotValue) 
			{
				*target = selfDelegate;
			}
		}
	}
	return slotValue;
}

/*printf("%p %s\n",self,  CSTRING(IoMessage_name(m)));*/

IoObject *IoObject_localsForward(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("localsForward", "CFunction used by Locals prototype for forwarding.")
	*/
    //IoObject *selfDelegate = IoObject_rawGetSlot_(self, IOSTATE->selfSymbol);
	
	IoObject *selfDelegate = PHash_at_(self->slots, IOSTATE->selfSymbol); // cheating a bit here 
	
	if (selfDelegate && selfDelegate != self) 
	{ 
		return IoObject_perform(selfDelegate, locals, m); 
	}
	
	return IONIL(self);
}

// name ------------------------------------------------------ 

int IoObject_isObject(IoObject *self)
{
	return (strcmp(IoObject_name(self), "Object") == 0);
}

IoObject *IoObject_lobbyPrint(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("print", "Prints a string representation of the object. Returns Nil.")
	*/
	
	IoState *state = IOSTATE;
	const char *name = IoObject_name(self);
	IoSymbol *key;
	
	IoObject_createSlotsIfNeeded(self);
	
	key = PHash_firstKey(self->slots);
	IoState_print_(IOSTATE, "%s_%p do(\n", name, (void *)self, name);
	IoState_print_(IOSTATE, "  appendProto(");
	
	{
		IoObject **proto = self->protos;
		
		while (*proto)
		{
			IoState_print_(IOSTATE, "%s_%p", name, (void *)*proto, name);
			proto ++;
			
			if (*proto)
			{
				IoState_print_(IOSTATE, ", ");
			}
		}
		
	}
	IoState_print_(IOSTATE, ")\n");
	
	while (key)
	{
		IoObject *value = PHash_at_(self->slots, key);
		IoState_print_(state, "  %s := ", CSTRING(key));
		if (ISSYMBOL(value)) IoState_print_(state, "\"");
		IoObject_defaultPrint(value); 
		if (ISSYMBOL(value)) IoState_print_(state, "\"");
		IoState_print_(state, "\n");
		key = PHash_nextKey(self->slots);
	}
    
	IoState_print_(IOSTATE, ")\n");
	
	return state->ioNil;
}

size_t IoObject_memorySizeFunc(IoObject *self)
{
	size_t t = sizeof(IoObject) + PHash_memorySize(self->slots);
	return t;
}

void IoObject_compactFunc(IoObject *self)
{
	PHash_compact(self->slots);
}

// proto methods ---------------------------------------------- 

IoObject *IoObject_protoPerform(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("perform(methodName, <arg1>, <arg2>, ...)", 
			"Performs the method corresponding to methodName with the arguments supplied.") 
	*/
	
	IoObject *slotName = IoMessage_locals_valueArgAt_(m, locals, 0);
	
	if (ISMESSAGE(slotName))
	{
		IOASSERT(IoMessage_argCount(m)==1, "perform takes a single argument when using a Message as an argument");
		return IoObject_perform(self, locals, slotName);  
	}
	
	IOASSERT(ISSYMBOL(slotName), "perform requires a String or Message argument");
	
	{
		IoObject *context;
		IoObject *v = IoObject_rawGetSlot_context_(self, slotName, &context);
		IoMessage *newMessage = IoMessage_newWithName_(IOSTATE, slotName);
		
		if (v)
		{
			int i;
			List *args = IoMessage_rawArgList(m);
			
			for (i = 1; i < List_size(args); i ++)
			{ 
				IoMessage_addArg_(newMessage, IoMessage_deepCopyOf_(List_at_(args, i))); 
			}
			
			return IoObject_activate(v, self, locals, newMessage, context);
		}
		
		return IoObject_forward(self, locals, newMessage);
	}
	
	return IoObject_forward(self, locals, m);
}

IoObject *IoObject_protoPerformWithArgList(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("performWithArgList(methodName, argList)", 
			"Performs the method corresponding to methodName with the arguments in the argList. ")
	*/
	
	IoSymbol *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoList *args = IoMessage_locals_listArgAt_(m, locals, 1);
	List *argList = IoList_rawList(args);
	IoObject *context;
	IoObject *v = IoObject_rawGetSlot_context_(self, slotName, &context);
	
	if (v)
	{
		IoMessage *newMessage = IoMessage_newWithName_(IOSTATE, slotName);
		int i, max = List_size(argList);
		
		for (i = 0; i < max; i ++)
		{ 
			IoMessage_addCachedArg_(newMessage, LIST_AT_(argList, i)); 
		}
		
		return IoObject_activate(v, self, locals, newMessage, context);
	}
	
	return IoObject_forward(self, locals, m);
}

IoObject *IoObject_protoWrite(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("write(<any number of arguments>)", 
			"Sends a print message to the evaluated result of each argument. Returns Nil.")
	*/
	
	int n, max = IoMessage_argCount(m);
	IoState *state = IOSTATE;
	
	for (n = 0; n < max; n ++)
	{
		IoObject *v = IoMessage_locals_valueArgAt_(m, locals, n);
		IoMessage_locals_performOn_(state->printMessage, locals, v);
	}
	
	return IONIL(self);
}

IoObject *IoObject_protoWriteLn(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("writeln(<any number of arguments>)", 
			"Same as write() but also writes a return character at the end. Returns Nil.")
	*/
	
	IoObject_protoWrite(self, locals, m);
	IoState_print_(IOSTATE, "\n");
	return IONIL(self);
}

inline IoObject *IoObject_initClone_(IoObject *self, IoObject *locals, IoMessage *m, IoObject *newObject)
{
	IoState *state = IOSTATE;
	IoObject *context;
	IoObject *initSlotValue = IoObject_rawGetSlot_context_(newObject, state->initSymbol, &context);
	
	if (initSlotValue) 
	{
		IoObject_activate(initSlotValue, newObject, locals, state->initMessage, context);
	}
	
	return newObject;
}

IoObject *IOCLONE(IoObject *self)
{
	IoState *state = IOSTATE;
	IoObject *newObject;
	
	IoState_pushCollectorPause(state);
	newObject = self->tag->cloneFunc(self);
	IoState_addValue_(state, newObject);
	IoState_popCollectorPause(state);
	return newObject;
}

IoObject *IoObject_clone(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("clone", "Returns a clone of the receiver.")
	*/
	
	IoObject *newObject = IOCLONE(self);
	return IoObject_initClone_(self, locals, m, newObject);
}

IoObject *IoObject_cloneWithoutInit(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("cloneWithoutInit", "Returns a clone of the receiver but does not call init.")
	*/
	
	return IOCLONE(self);
}

IoObject *IoObject_shallowCopy(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("shallowCopy", "Returns a shallow copy of the receiver.")
	*/
	
	IoObject *newObject = IoObject_new(IOSTATE); 
	IoSymbol *key = PHash_firstKey(self->slots);
	
	while (key)
	{
		IoObject *value = PHash_at_(self->slots, key);
		IoObject_setSlot_to_(newObject, key, value);
		key = PHash_nextKey(self->slots);
	}  
	
	return newObject;
}

IoObject *IoObject_duplicate(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("duplicate", "Creates a new copy of the receiver, including its proto list.")
	*/

	IoObject *newObject = IoObject_new(IOSTATE); 
	memmove(newObject, self, sizeof(*self));
	return newObject;
}

// lobby methods ---------------------------------------------- 

IoObject *IoObject_protoSet_to_(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("setSlot(slotNameString, valueObject)", 
			"Sets the slot slotNameString in the receiver to 
hold valueObject. Returns valueObject.")
	*/
	
	//IoSymbol *slotName  = IoMessage_locals_firstStringArg(m, locals);
	//IoObject *slotValue = IoMessage_locals_quickValueArgAt_(m, locals, 1);
	IoSymbol *slotName  = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject *slotValue = IoMessage_locals_valueArgAt_(m, locals, 1);
	IoObject_inlineSetSlot_to_(self, slotName, slotValue);
	return slotValue;
}

IoObject *IoObject_protoSetSlotWithType(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("setSlotWithType(slotNameString, valueObject)", 
			"Sets the slot slotNameString in the receiver to 
hold valueObject and sets the type slot of valueObject to be slotNameString. Returns valueObject.")
	*/
	
	IoSymbol *slotName  = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject *slotValue = IoMessage_locals_valueArgAt_(m, locals, 1);
	IoObject_inlineSetSlot_to_(self, slotName, slotValue);
	if (PHash_at_(slotValue->slots, IOSTATE->typeSymbol) == 0x0)
	{
		IoObject_inlineSetSlot_to_(slotValue, IOSTATE->typeSymbol, slotName);
	}
	return slotValue;
}

IoObject *IoObject_localsUpdateSlot(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("updateLocalSlot(slotNameString, valueObject)", "")
	*/
	
	IoSymbol *slotName  = IoMessage_locals_firstStringArg(m, locals);
	//IoSymbol *slotName  = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject *obj = IoObject_rawGetSlot_(self, slotName);
	
	if (obj)
	{
		//IoObject *slotValue = IoMessage_locals_valueArgAt_(m, locals, 1);
		IoObject *slotValue = IoMessage_locals_quickValueArgAt_(m, locals, 1);
		IoObject_inlineSetSlot_to_(self, slotName, slotValue);
		return slotValue;  
	}
	else
	{
		IoObject *theSelf = IoObject_rawGetSlot_(self, IOSTATE->selfSymbol);
		
		if (theSelf) 
		{
			return IoObject_perform(theSelf, locals, m);
			/*
			 obj = IoObject_rawGetSlot_(theSelf, slotName);
			 if (obj)
			 {
				 
				 IoObject_inlineSetSlot_to_(theSelf, slotName, slotValue);
				 return slotValue;
			 }
			 */
		}
	}
	
	IoState_error_(IOSTATE, m,
							   "updateSlot - slot with name `%s' not found in `%s'. Use := to create slots.",
							   CSTRING(slotName), IoObject_name(self));
	
	return IONIL(self);        
}

IoObject *IoObject_protoUpdateSlot_to_(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("updateSlot(slotNameString, valueObject)", 
			"Same as setSlot(), but raises an error if the slot does not 
already exist in the receiver's slot lookup path.")
	*/
	
	IoSymbol *slotName  = IoMessage_locals_firstStringArg(m, locals);
	IoObject *slotValue = IoMessage_locals_quickValueArgAt_(m, locals, 1);
	IoObject *obj = IoObject_rawGetSlot_(self, slotName);
	
	if (obj)
	{ 
		IoObject_inlineSetSlot_to_(self, slotName, slotValue); 
	}
	else
	{
		IoState_error_(IOSTATE, m, "Slot %s not found. Must define slot using := operator before updating.", 
								   CSTRING(slotName));
	}
	
	return slotValue;
}

IoObject *IoObject_protoGetSlot_(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("getSlot(slotNameString)", 
		   "Returns the value of the slot named slotNameString 
(following the lookup path) or nil if no such slot is found.")
	*/
	
	IoSymbol *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	return IoObject_getSlot_(self, slotName);
}

IoObject *IoObject_protoGetLocalSlot_(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("getLocalSlot(slotNameString)", 
		   "Returns the value of the slot named slotNameString (not looking in the object's protos) or nil if no such slot is found.")
	*/	
	
	IoSymbol *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	
	if (self->ownsSlots)
	{
		IoObject *v = PHash_at_(self->slots, slotName);
		if (v) return v; 
	}
	
	return IONIL(self);
}

IoObject *IoObject_protoHasLocalSlot(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("hasLocalSlot(slotNameString)", 
			"Returns true if the slot exists in the receiver or false otherwise.")
	*/
	
	IoSymbol *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject_createSlotsIfNeeded(self);
	return IOBOOL(self, PHash_at_(self->slots, slotName) != 0x0);
}

IoObject *IoObject_protoRemoveSlot(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("removeSlot(slotNameString)", 
			"Removes the specified slot (only) in the receiver if it exists. Returns self.")
	*/
	
	IoSymbol *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject_createSlotsIfNeeded(self);
	PHash_removeKey_(self->slots, slotName);
	return self;
}

IoObject *IoObject_protoSlotNames(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("slotNames", 
			"Returns a list of strings containing the names of the 
slots in the receiver (but not in it's lookup path).")
	*/
	
	IoObject_createSlotsIfNeeded(self);
	
	{
		IoList *slotNames = IoList_new(IOSTATE);
		IoSymbol *slotName = PHash_firstKey(self->slots);
		
		while (slotName)
		{ 
			IoList_rawAppend_(slotNames, slotName);
			slotName = PHash_nextKey(self->slots);
		}
        
		return slotNames;
	}
}

/*
 docSlot("forward")
 docDescription("""Called when the receiver is sent a message it doesn't recognize. 
 Default implementation raises an "Object doesNotRespond" exception. 
 Subclasses can override this method to implement proxies or special error handling.""")
 
 Example:
 
 <pre>
 myProxy forward = method(
					 messageName := thisMessage name
					 arguments := thisMessage arguments
					 myObject doMessage(thisMessage)
					 )
 </pre>
 
 */
 
 /*
IoObject *IoObject_forward_(IoObject *self, IoObject *locals, IoMessage *m)
{

	IoState_error_(IOSTATE, m, "%s does not respond to message '%s'", 
							   IoObject_name(self), 
							   CSTRING(IoMessage_name(m)));
	return IONIL(self);
}
*/

IoObject *IoObject_ancestorWithSlot(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("ancestorWithSlot(slotName)", 
			"Returns the first ancestor of the receiver that contains 
a slot of the specified name or Nil if none is found.")
	*/ 
	
	IoObject *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject **proto = self->protos;
	
	while (*proto)
	{
		IoObject *context = 0x0;
		IoObject *v = IoObject_rawGetSlot_context_((*proto), slotName, &context);
		
		if (v) 
		{
			return context;
		}
		
		proto ++;
	}
	
	return IONIL(self);
}

IoObject *IoObject_contextWithSlot(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("contextWithSlot(slotName)", 
			"Returns the first context (starting with the receiver and following the lookup path) 
that contains a slot of the specified name or Nil if none is found.")
	*/ 
	
	IoObject *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject *context = 0x0;
	IoObject_rawGetSlot_context_(self, slotName, &context);
	return context ? context : IONIL(self);
}

// --------------------------------------------------------------------------- 

IoObject *IoObject_rawDoString_label_(IoObject *self, IoSymbol *string, IoSymbol *label)
{
	IoMessage *cm = NULL;
	IoMessage *messageForString = NULL;
	IoMessage *newMessage = NULL;
	IoState *state = IOSTATE;
	
	if(!ISSEQ(string))
	{ 
		IoState_error_(state, 0x0, "IoObject_rawDoString_label_ requires a string argument");
	}
	
	{
		IoSymbol *internal;
		IoState_pushCollectorPause(state);
		
		internal = IOSYMBOL("[internal]");
		cm = IoMessage_newWithName_label_(state, IOSYMBOL("Compiler"), internal);
		messageForString = IoMessage_newWithName_label_(state, IOSYMBOL("messageForString"), internal);
		
		IoMessage_rawSetAttachedMessage(cm, messageForString);
		IoMessage_addCachedArg_(messageForString, string);
		IoMessage_addCachedArg_(messageForString, label);
		
		//printf("cm = %p\n", (void *)cm);
		//printf("messageForString = %p\n", (void *)messageForString);
		newMessage = IoMessage_locals_performOn_(cm, self, self); 
		
		IoState_stackRetain_(state, newMessage); // needed?
		IoState_popCollectorPause(state);
		
		//IoMessage *newMessage = IoMessage_newFromText_label_(state, CSTRING(string), CSTRING(label));
		
		if (newMessage) 
		{
			return IoMessage_locals_performOn_(newMessage, self, self); 
		}
		
		IoState_error_(state, 0x0, "no message compiled\n");
		return IONIL(self);
	}
}

IoObject *IoObject_doMessage(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("doMessage(aMessage, optionalContext)", 
			"Evaluates the message object in the context of the receiver. 
Returns the result. optionalContext can be used to specific the locals 
context in which the message is evaluated.")
	*/
	
	IoMessage *aMessage = IoMessage_locals_messageArgAt_(m, locals, 0);
	IoObject *context = self;
	
	if (IoMessage_argCount(m) > 1)
	{ 
		context = IoMessage_locals_valueArgAt_(m, locals, 1); 
	}
	
	return IoMessage_locals_performOn_(aMessage, context, self);
}

IoObject *IoObject_doString(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("doString(aString)", 
			"Evaluates the string in the context of the receiver. Returns the result. ")
	*/
	
	IoSymbol *string = IoMessage_locals_seqArgAt_(m, locals, 0);
	IoSymbol *label;
	IoObject *result;
	
	if (IoMessage_argCount(m) > 1)
	{
		label = IoMessage_locals_symbolArgAt_(m, locals, 1);
	}
	else
	{
		label = IOSYMBOL("doString");
	}
	
	IoState_pushRetainPool(IOSTATE);
	result = IoObject_rawDoString_label_(self, string, label);
	IoState_popRetainPoolExceptFor_(IOSTATE, result);
	return result;
}

IoObject *IoObject_doFile(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("doFile(pathString)", 
			"Evaluates the File in the context of the receiver. Returns the result. ")
	*/
	
	IoSymbol *path = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoFile *file = IoFile_newWithPath_(IOSTATE, path);
	IoSymbol *string = (IoSymbol *)IoSeq_rawAsSymbol(IoFile_contents(file, locals, m));
	
	if (IoSeq_rawSize(string))
	{
		IoList *argsList = IoList_new(IOSTATE);
		int argn = 1;
		IoObject *arg = IoMessage_locals_valueArgAt_(m, locals, argn);
		
		while (arg && !ISNIL(arg))
		{
			IoList_rawAppend_(argsList, arg);
			argn ++;
			arg = IoMessage_locals_valueArgAt_(m, locals, argn);
		}
		
		if (IoList_rawSize(argsList))
		{ 
			IoObject_setSlot_to_(self, IOSYMBOL("args"), argsList); 
		}
		
		return IoObject_rawDoString_label_(self, string, path);
	}
	
	return IONIL(self);
}

IoObject *IoObject_isIdenticalTo(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("isIdenticalTo(aValue)", 
			"Returns true if the receiver is identical to aValue, false otherwise. ")
	*/
	
	IoObject *other = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, self == other);
}

IoObject *IoObject_equals(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("== aValue", 
			"Returns true if receiver and aValue are equal, false otherwise. ")
	*/
	
	IOASSERT(IoMessage_argCount(m), "compare requires argument");
	
	{
		IoObject *other = IoMessage_locals_valueArgAt_(m, locals, 0);
		return IOBOOL(self, IoObject_compare(self, other) == 0);
	}
}

IoObject *IoObject_notEquals(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("!= aValue", 
			"Returns true the receiver is not equal to aValue, false otherwise. ")
	*/
	
	IoObject *other = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, IoObject_compare(self, other) != 0);
}

IoObject *IoObject_foreachSlot(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("foreach([name,] value, message)", 
			"""For each slot, set name to the slot's 
name and value to the slot's value and execute message. Example:
<pre>
myObject foreach(n, v, 
				 writeln("slot ", n, " = ", v type)
				 )
myObject foreach(v, 
				 writeln("slot type ", v type)
				 )
</pre>
""")
	*/
	
	IoSymbol *keyName;
	IoSymbol *valueName;
	IoMessage *doMessage;
	IoObject *key = PHash_firstKey(self->slots);
	IoObject *result = IONIL(self);
	
	IoState_pushRetainPool(IOSTATE);
	IoMessage_foreachArgs(m, self, &keyName, &valueName, &doMessage);
	
	while (key)
	{
		IoState_clearTopPool(IOSTATE);
		
		{
			IoObject *value = PHash_at_(self->slots, key);
			
			if (keyName)
			{
				IoObject_setSlot_to_(locals, keyName, key);
			}
			
			IoObject_setSlot_to_(locals, valueName, value);
			result = IoMessage_locals_performOn_(doMessage, locals, locals);
			
			if (IoState_handleStatus(IOSTATE)) 
			{
				goto done;
			}
			
			key = PHash_nextKey(self->slots);
		}
	}
done:
		IoState_popRetainPoolExceptFor_(IOSTATE, result);
	return result;
}

IoObject *IoObject_subtract(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("- (aNumber)", 
			"Returns the negative version of aNumber. 
Raises an exception if argument is not a number.")
	*/
	
	IoNumber *num = IoMessage_locals_numberArgAt_(m, locals, 0);
	return IONUMBER(- IoNumber_asDouble(num));
}

IoObject *IoObject_self(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("self ", "Returns self.")
	*/
	
	return self; 
}

IoObject *IoObject_locals(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("thisLocalContext ", "Returns current locals.")
	*/
	
	return locals; 
}

// message callbacks -------------------------------------- 

const char *IoObject_name(IoObject *self) 
{ 
	return IoTag_name(self->tag); 
}

int IoObject_compare(IoObject *self, IoObject *v)
{
	if (self == v) 
	{
		return 0;
	}
	
	if (self->tag->compareFunc) 
	{ 
		return (self->tag->compareFunc)(self, v); 
	}
	
	return IoObject_defaultCompare(self, v);
}

int IoObject_defaultCompare(IoObject *self, IoObject *v)
{
	int d = -((ptrdiff_t)self->tag - (ptrdiff_t)v->tag);
	
	if (d == 0) 
	{ 
		return ((ptrdiff_t)self) - ((ptrdiff_t)v); 
	}
	
	return d;
}

int IoObject_sortCompare(IoObject **self, IoObject **v) 
{ 
	return IoObject_compare(*self, *v); 
}

size_t IoObject_memorySize(IoObject *self)
{ 
	return (self->tag->memorySizeFunc) ? (self->tag->memorySizeFunc)(self) : 0; 
}

void IoObject_compact(IoObject *self)
{ 
	if (self->tag->compactFunc) 
	{ 
		(self->tag->compactFunc)(self); 
	}
}


// lobby methods ---------------------------------------------- 

IoObject *IoObject_memorySizeMethod(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*
	 docSlot("memorySize", "Return the amount of memory used by the object.")
	 */
	return IONUMBER(IoObject_memorySize(self)); 
}

IoObject *IoObject_compactMethod(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*
	 docSlot("compact", "Compact the memory for the object if possible. Returns self.")
	 */
	 
	IoObject_compact(self); 
	return self; 
}

IoObject *IoObject_type(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("type", "Returns a string containing the name of the type of Object (Number, String, etc).")
	*/
	
	return IOSYMBOL((char *)IoObject_name(self)); 
}

void IoObject_defaultPrint(IoObject *self)
{
	if (ISSYMBOL(self))
	{
		IoSeq_rawPrint(self); 
	}
	else if (ISNUMBER(self))
	{
		IoNumber_print(self);
	}
	else
	{
		IoState_print_(IOSTATE, "%s_%p", IoObject_name(self), self);
		
		if (ISMESSAGE(self))
		{
			IoState_print_(IOSTATE, " '%s'", CSTRING(IoMessage_name(self)));
		}
	}
}

void IoObject_print(IoObject *self) 
{
	IoMessage_locals_performOn_(IOSTATE->printMessage, self, self); 
    // using self as locals hack 
}

IoObject *IoObject_evalArg(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("(expression)", "The '' method evaluates the argument and returns the result.")
	*/
	/*#io
	docSlot("evalArg(expression)", "The '' method evaluates the argument and returns the result.")
	*/	
	IOASSERT(IoMessage_argCount(m) > 0, "argument required\n");
	/* eval the arg and return a non-Nil so an attached else() won't get performed */
	return IoMessage_locals_valueArgAt_(m, locals, 0);
}

IoObject *IoObject_evalArgAndReturnSelf(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("evalArgAndReturnSelf(expression)", "Evaluates the argument and returns the target.")
	*/
	
	IoObject_evalArg(self, locals, m);
	return self;
}

IoObject *IoObject_evalArgAndReturnNil(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("evalArgAndReturnNil(expression)", "Evaluates the argument and returns nil.")
	*/
	
	IoObject_evalArg(self, locals, m);
	return IONIL(self);
}

IoObject *IoObject_isLessThan_(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("< (expression)", "Evaluates argument and returns self if self is less or Nil if not.")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, IoObject_compare(self, v) < 0);
}

IoObject *IoObject_isLessThanOrEqualTo_(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("<= (expression)", 
			"Evaluates argument and returns self if self is less 
than or equal to it, or Nil if not.")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, IoObject_compare(self, v) <= 0);
}

IoObject *IoObject_isGreaterThan_(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("> (expression)", 
			"Evaluates argument and returns self if self is greater than it, or Nil if not.")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, IoObject_compare(self, v) > 0);
}

IoObject *IoObject_isGreaterThanOrEqualTo_(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot(">= (expression)", 
			"Evaluates argument and returns self if self is greater 
than or equal to it, or Nil if not.")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, IoObject_compare(self, v) >= 0);
}

IoObject *IoObject_uniqueId(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("uniqueId", "Returns a Number containing a unique id for the receiver.")
	*/
	
	return IONUMBER((double)((size_t)self)); 
}

IoObject *IoObject_do(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("do(expression)", 
			"Evaluates the message in the context of the receiver. Returns self.")
	*/
	
	if (IoMessage_argCount(m) != 0) 
	{
		IoMessage *argMessage = IoMessage_rawArgAt_(m, 0);
		IoMessage_locals_performOn_(argMessage, self, self);
	}
	
	return self;
}

IoObject *IoObject_message(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("message(expression)", 
			"Return the message object for the argument or Nil if there is no argument.")
	*/
	
	return IoMessage_argCount(m) ? IoMessage_rawArgAt_(m, 0) : IONIL(self);
}


// inline these -------------------------------------------------

int IoObject_hasCloneFunc_(IoObject *self, TagCloneFunc *func)
{
    /*
	if (ISWAITINGFUTURE(self)) 
	{
		IoFuture_rawWaitOnResult(self);
	}
    */
    
	return (self->tag->cloneFunc == func);
}

// -------------------------------------------- 

char *IoObject_markColorName(IoObject *self)
{
	return Collector_colorNameFor_(IOCOLLECTOR, self);
}

void IoSymbol_println(IoSymbol *self)
{
	printf("%s\n", CSTRING(self));
}

void IoObject_show(IoObject *self)
{
	printf("  %p %s\n", (void *)self, IoObject_name(self));
	PHash_doOnKeys_(self->slots, (PHashDoCallback *)IoSymbol_println); 
}

IoObject *IoObject_setIsActivatable(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("setIsActivatable(aValue)", 
			"When called with a non-Nil aValue, sets the object 
to call it's activate slot when accessed as a value. Turns this behavior 
off if aValue is Nil. Only works on Objects which are not Activatable 
Primitives (such as CFunction or Block). Returns self.")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	IoObject *objectProto = IoState_protoWithInitFunction_(IOSTATE, (IoStateProtoFunc *)IoObject_proto);
	
	objectProto->tag->activateFunc = (TagActivateFunc *)IoObject_activateFunc;
	
	self->isActivatable = ISTRUE(v);
	
	return self;
}

IoObject *IoObject_isActivatable(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("isActivatable", 
			"Returns true if the receiver is activatable, false otherwise.")
	*/
	
	return self->isActivatable ? IOTRUE(self) : IOFALSE(self);
}

IoObject *IoObject_rawDoMessage(IoObject *self, IoMessage *m)
{
	return IoObject_eval(self, m, self);
}

//#define IO_DEBUG_STACK

inline IoObject *IoObject_evalAttached(IoObject *self, IoMessage *m, IoObject *locals)
{
	IoState *state = IOSTATE;
	IoObject *c = self;
	IoObject *r;

	do
	{
		r = IOMESSAGEDATA(m)->cachedResult;
		
		if (r)
		{
			c = r;
		}
		else
		{
			c = c->tag->performFunc(c, locals, m);
			if (state->stopStatus) return state->returnValue;
		}
	} while ((m = IOMESSAGEDATA(m)->attachedMessage));
	
	return r;
}

IoObject *IoObject_eval(IoObject *self, IoMessage *m, IoObject *locals)
{
	IoState *state = IOSTATE;
	IoObject *r;
	
	state->stopStatus = 0;
	
	do
	{
		r = IoObject_evalAttached(self, m, locals);
		if (state->stopStatus) return state->returnValue;
	} while ((m = IOMESSAGEDATA(m)->nextMessage));
	
	return r;
}

IoObject *IoObject_eval2(IoObject *self, IoMessage *message, IoObject *locals)
{
	IoState *state = IOSTATE;
	IoObject *r = state->ioNil;
	IoMessage *m = message;
	IoObject *c = self;
	
	do
	{
		do
		{
			r = IOMESSAGEDATA(m)->cachedResult;
			
			if (!r)
			{
				//printf("%s\n", CSTRING(IoMessage_name(m)));
				r = c->tag->performFunc(c, locals, m);
				
				if (state->stopStatus != MESSAGE_STOP_STATUS_NORMAL)
				{
					return state->returnValue;
				}
			}
			
			c = r;
			
		} while ((m = IOMESSAGEDATA(m)->attachedMessage));
		
		c = locals;
		
	} while ((m = IOMESSAGEDATA(m)->nextMessage));
	
	return r;
}

/*
IoNumber *IoObject_getNumberSlot(IoObject *self, 
								IoObject *locals, 
								IoMessage *m, 
								IoSymbol *slotName)
{
	IoObject *v  = IoObject_getSlot_(self, slotName);			
	IOASSERT(ISNUMBER(v),  CSTRING(slotName));
	return v;
}
*/

ByteArray *IoObject_rawGetByteArraySlot(IoObject *self, 
								IoObject *locals, 
								IoMessage *m, 
								IoSymbol *slotName)
{
	IoSeq *seq  = IoObject_getSlot_(self, slotName);			
	IOASSERT(ISSEQ(seq),  CSTRING(slotName));
	return IoSeq_rawByteArray(seq);
}

ByteArray *IoObject_rawGetMutableByteArraySlot(IoObject *self, 
									  IoObject *locals, 
									  IoMessage *m, 
									  IoSymbol *slotName)
{
	IoSeq *seq  = IoObject_getSlot_(self, slotName);			
	IOASSERT(ISSEQ(seq), CSTRING(slotName));
	return IoSeq_rawByteArray(seq);
}


IoObject *IoObject_argIsActivationRecord(IoObject *self, IoObject *locals, IoMessage *m)
{
	return IOBOOL(self, PHash_at_(self->slots, IOSTATE->callSymbol) != 0x0);
}

IoObject *IoObject_argIsCall(IoObject *self, IoObject *locals, IoMessage *m)
{
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	//printf("v->tag->name = '%s'\n", v->tag->name);
	return IOBOOL(self, ISACTIVATIONCONTEXT(v));
}

/*
IoObject *IoObject_unpack(IoObject *self, IoObject *locals, IoMessage *m)
{
    const char *const s = IoMessage_locals_cStringArgAt_(m, locals, 0);
    return IoUnpack_unpack(IOSTATE, s);
}
*/

// free listeners ---------------------------------------------

void IoObject_addListener_(IoObject *self, void *listener)
{		
	if (self->listeners == 0x0) 
	{
		self->listeners = List_new();
	}
	
	List_append_(self->listeners, listener);
}

void IoObject_removeListener_(IoObject *self, void *listener)
{	
	if (self->listeners) 
	{
		List_remove_(self->listeners, listener);
		
		if (List_size(self->listeners) == 0)
		{
			List_free(self->listeners);
			self->listeners = 0x0;
		}
	}
}


