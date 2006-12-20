/*   Copyright (c) 2003, Steve Dekorte
*   All rights reserved. See _BSDLicense.txt.
*/

#include "Io2Objc.h"
#include "List.h"
#include "IoBlock.h"

#define DATA(self) ((Io2ObjcData *)IoObject_dataPointer(self))

IoTag *Io2Objc_tag(void *state)
{
	IoTag *tag = IoTag_newWithName_("Io2Objc");
	tag->state = state;
	tag->cloneFunc = (TagCloneFunc *)Io2Objc_rawClone;
	tag->freeFunc = (TagFreeFunc *)Io2Objc_free;
	tag->markFunc = (TagMarkFunc *)Io2Objc_mark;
	tag->performFunc = (TagPerformFunc *)Io2Objc_perform;
	return tag;
}

Io2Objc *Io2Objc_proto(void *state)
{
	IoObject *self = IoObject_new(state);
	self->tag = Io2Objc_tag(state);

	IoObject_setDataPointer_(self, objc_calloc(1, sizeof(Io2ObjcData)));
	DATA(self)->returnBufferSize = 128;
	DATA(self)->returnBuffer = objc_malloc(DATA(self)->returnBufferSize);

	DATA(self)->object = nil;
	DATA(self)->bridge = IoObjcBridge_sharedBridge();
	assert(DATA(self)->bridge != NULL);
	IoState_registerProtoWithFunc_(state, self, Io2Objc_proto);

	IoMethodTable methodTable[] = {
		{"newSubclassNamed:", Io2Objc_newSubclassNamed},
		{"metaclass", Io2Objc_metaclass},
		{"setSlot", Io2Objc_setSlot},
		{"updateSlot", Io2Objc_updateSlot},
		{"super", Io2Objc_super},
		{"ioValue", Io2Objc_ioValue},
		//{"print", Io2Objc_print},
		//{"slotSummary", Io2Objc_slotSummary},
		{NULL, NULL}
	};
	IoObject_addMethodTable_(self, methodTable);

	return self;
}

Io2Objc *Io2Objc_rawClone(Io2Objc *proto)
{
	IoObject *self = IoObject_rawClonePrimitive(proto);
	IoObject_setDataPointer_(self, cpalloc(DATA(proto), sizeof(Io2ObjcData)));
	DATA(self)->returnBufferSize = 128;
	DATA(self)->returnBuffer = objc_malloc(DATA(self)->returnBufferSize);
	return self;
}

Io2Objc *Io2Objc_new(void *state)
{
	IoObject *proto = IoState_protoWithInitFunction_(state, Io2Objc_proto);
	return IOCLONE(proto);
}

Io2Objc *Io2Objc_newWithId_(void *state, id obj)
{
	Io2Objc *self = Io2Objc_new(state);
	Io2Objc_setObject(self, obj);
	return self;
}

void Io2Objc_free(Io2Objc *self)
{
	id object = DATA(self)->object;
	if (IoObjcBridge_sharedBridge()) IoObjcBridge_removeId_(DATA(self)->bridge, object);
	//printf("Io2Objc_free %p that referenced a %s\n", (void *)object, [[object className] cString]);
	if (object != nil && (((Class)object)->info & CLS_META) != CLS_META)
		[object autorelease];
	objc_free(DATA(self)->returnBuffer);
	objc_free(DATA(self));
	IoObject_dataPointer(self) = NULL;
}

void Io2Objc_mark(Io2Objc *self)
{
	IoObject_shouldMark(DATA(self)->bridge);
}

void Io2Objc_setBridge(Io2Objc *self, void *bridge)
{
	DATA(self)->bridge = bridge;
}

void Io2Objc_setObject(Io2Objc *self, void *object)
{
	if (object != nil && (((Class)object)->info & CLS_META) != CLS_META)
		DATA(self)->object = [(id)object retain];
	else
		DATA(self)->object = (id)object;
}

void *Io2Objc_object(Io2Objc *self)
{
	return DATA(self)->object;
}

void Io2Objc_nullObjcBridge(Io2Objc *self)
{
	DATA(self)->bridge = NULL;
}

/* ----------------------------------------------------------------- */

IoObject *Io2Objc_perform(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	/* --- get the method signature ------------ */
	NSInvocation *invocation = nil;
	NSMethodSignature *methodSignature;
	char *methodName = IoObjcBridge_objcMethodFor_(DATA(self)->bridge, CSTRING(IoMessage_name(m)));
	SEL selector = sel_getUid(methodName);
	id object = DATA(self)->object;
	BOOL debug = IoObjcBridge_rawDebugOn(DATA(self)->bridge);
	IoObject *result;

	//NSLog(@"[%@<%i> %s]", NSStringFromClass( [object class] ), object, CSTRING(m->method));

	// see if receiver can handle message -------------

	BOOL respondsToSelector;
	if (object != nil && (((Class)object)->info & CLS_META) == CLS_META)
	{
		((Class)object)->info ^= CLS_CLASS;
		((Class)object)->info ^= CLS_META;
		respondsToSelector = [object respondsToSelector:selector];
		((Class)object)->info ^= CLS_META;
		((Class)object)->info ^= CLS_CLASS;
	}
	else
		respondsToSelector = [object respondsToSelector:selector];

	if (!respondsToSelector)
		return IoObject_perform(self, locals, m);

	methodSignature = [object methodSignatureForSelector:selector];

	/* --- create an invocation ------------- */
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	[invocation setTarget:object];
	[invocation setSelector:selector];

	if (debug)
	{
		char *cType = (char *)[methodSignature methodReturnType];
		IoState_print_(IOSTATE, "Io -> Objc (%s)", IoObjcBridge_nameForTypeChar_(DATA(self)->bridge, *cType));
		IoState_print_(IOSTATE, "%s(", methodName);
	}

	/* --- attach arguments to invocation --- */
	{
		int n, max = [methodSignature numberOfArguments];
		for (n = 2; n < max; n++)
		{
			char *error;
			char *cType = (char *)[methodSignature getArgumentTypeAtIndex:n];
			IoObject *ioValue = IoMessage_locals_valueArgAt_(m, locals, n-2);
			void *cValue = IoObjcBridge_cValueForIoObject_ofType_error_(DATA(self)->bridge, ioValue, cType, &error);
			if (debug)
			{
				printf("%s", IoObjcBridge_nameForTypeChar_(DATA(self)->bridge, *cType));
				if (n < max - 1)
					printf(", ");
			}
			if (error)
				IoState_error_(IOSTATE, m, "Io Io2Objc perform %s - argtype:'%s' argnum:%i", error, cType, n-2);
			[invocation setArgument:cValue atIndex:n]; /* copies the contents of value as a buffer of the appropriate size */
		}
	}

	if (debug)
		IoState_print_(IOSTATE, ")\n");

	/* --- invoke --------------------------- */
	{
		NS_DURING
			[invocation invoke];
		NS_HANDLER
			IoState_error_(IOSTATE, m, "Io Io2Objc perform while sending '%s' %s - %s", methodName, [[localException name] cString], [[localException reason] cString]);
		NS_ENDHANDLER
	}

	/* --- return result --------------------------- */
	{
		char *error;
		char *cType = (char *)[methodSignature methodReturnType];
		unsigned int length = [methodSignature methodReturnLength];

		if (*cType == 'v')
			return IONIL(self); /* void */

		if ((unsigned int)DATA(self)->returnBufferSize < length)
		{
			DATA(self)->returnBuffer = objc_realloc(DATA(self)->returnBuffer, length);
			DATA(self)->returnBufferSize = length;
		}

		[invocation getReturnValue:DATA(self)->returnBuffer];
		result = IoObjcBridge_ioValueForCValue_ofType_error_(DATA(self)->bridge, DATA(self)->returnBuffer, cType, &error);
		if (error)
			IoState_error_(IOSTATE, m, "Io Io2Objc perform %s - return type:'%s'", error, cType);
	}
	return result;
}

void forwardInvocation(id self, SEL sel, NSInvocation *invocation)
{
	Class save, class;
	IoObject *result, *context;
	IoObjcBridge *bridge = IoObjcBridge_sharedBridge();
	IoObject *target = IoObjcBridge_proxyForId_(bridge, [invocation target]);
	const char *returnType = [[invocation methodSignature] methodReturnType];
	IoMessage *message = IoObjcBridge_ioMessageForNSInvocation_(bridge, invocation);
	
	char *name = objc_malloc(2 + strlen(sel_getName([invocation selector])));
	name[0] = '-';
	name[1] = 0;
	IoSymbol *symbol = IoState_symbolWithCString_(bridge->state, strcat(name, sel_getName([invocation selector])));
	objc_free(name);

	for (class = self->isa ; class != nil ; class = class->super_class)
	{
		Io2Objc *io2objc = Hash_at_(((IoObjcBridgeData *)DATA(bridge))->io2objcs, class);

		if (io2objc == NULL)
			continue;

		IoObject *slotValue = IoObject_rawGetSlot_context_(io2objc, symbol, &context);

		if (slotValue == NULL)
			continue;

		save = DATA(target)->object->isa;
		DATA(target)->object->isa = class;
		result = IoObject_activate(slotValue, target, target, message, context);
		DATA(target)->object->isa = save;

		if (*returnType != 'v')
		{
			char *error;
			void *cResult = IoObjcBridge_cValueForIoObject_ofType_error_(bridge, result, (char *)returnType, &error);
			if (error)
				IoState_error_(bridge->state, message, "Io Io2Objc forwardInvocation: %s %s - return type:'%s'", [[invocation description] cString], error, returnType);
			[invocation setReturnValue:cResult];
		}
		return;
	}
	IoState_error_(bridge->state, message, "'%s' does not respond to message '%s'", [invocation target]->isa->name, CSTRING(symbol));
}

BOOL respondsToSelector(id self, SEL sel, SEL selector)
{
	Io2Objc *io2objc = Hash_at_(((IoObjcBridgeData *)DATA(IoObjcBridge_sharedBridge()))->io2objcs, self->isa);
	IoObjcBridge *bridge = DATA(io2objc)->bridge;
	IoState *state = io2objc->tag->state;

	BOOL debug = IoObjcBridge_rawDebugOn(bridge);
	char *ioMethodName = IoObjcBridge_ioMethodFor_(bridge, (char *)sel_getName(selector));

	if (debug)
		IoState_print_(state, "[Io2Objc respondsToSelector:\"%s\"] ", ioMethodName);

	BOOL result = class_getInstanceMethod(self->isa, selector) ? YES : NO;

	if (debug)
		IoState_print_(state, "= %i\n", result);

	return result;
}

NSMethodSignature *methodSignatureForSelector(id self, SEL sel, SEL selector)
{
	struct objc_method *method = class_getInstanceMethod(self->isa, selector);
	if (method)
		return [NSMethodSignature signatureWithObjCTypes:method->method_types];
	else
		return nil;
}

Io2Objc *Io2Objc_newSubclassNamed(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	Class class = objc_makeClass(IoMessage_locals_cStringArgAt_(m, locals, 0), DATA(self)->object->isa->name, NO);
	objc_addClass(class);
	class_addMethod(class, sel_getUid("forwardInvocation:"), "v12@0:4@8", (IMP)forwardInvocation, NO);
	class_addMethod(class, sel_getUid("forwardInvocation:"), "v12@0:4@8", (IMP)forwardInvocation, YES);
	class_addMethod(class, sel_getUid("respondsToSelector:"), "C12@0:4:8", (IMP)respondsToSelector, YES);
	class_addMethod(class, sel_getUid("methodSignatureForSelector:"), "@12@0:4:8", (IMP)methodSignatureForSelector, YES);
	((IoObjcBridgeData *)DATA(DATA(self)->bridge))->allClasses = NULL;
	return IoObjcBridge_proxyForId_(DATA(self)->bridge, class);
}

IoObject *Io2Objc_metaclass(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	return IoObjcBridge_proxyForId_(DATA(self)->bridge, DATA(self)->object->isa);
}

IoObject *Io2Objc_setSlot(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	char *name = IoMessage_locals_cStringArgAt_(m, locals, 0);
	if (*name == '"') *(++name + strlen(name) - 1) = 0;
	IoSymbol *slotName = IOSYMBOL(name);
//	IoSymbol *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject *slotValue = IoMessage_locals_valueArgAt_(m, locals, 1);
	if (ISBLOCK(slotValue))
	{
		unsigned int argCount = IoMessage_argCount(slotValue);
		unsigned int expectedArgCount = 0;
		const char *name = CSTRING(slotName);
		while (*name) expectedArgCount += (*name++ == ':');
		if (argCount != expectedArgCount)
			IoState_error_(IOSTATE, m, "Method '%s' is waiting for %i arguments, %i given\n", CSTRING(slotName), expectedArgCount, argCount);
		Class class = DATA(self)->object;
		if ((class->info & CLS_CLASS) != CLS_CLASS && (class->info & CLS_META) != CLS_META)
			IoState_error_(IOSTATE, m, "You cannot add method '%s' to instance '%s'\n", CSTRING(slotName), [[class description] cString]);
		struct objc_method *method = class_getInstanceMethod(class, sel_getUid(CSTRING(slotName)));
		if (method)
		{
			SEL selector = sel_get_typed_uid(CSTRING(slotName), method->method_types);
			if (!selector) selector = sel_register_typed_name(CSTRING(slotName), method->method_types);
			class_addMethod(class, selector, method->method_types, __objc_get_forward_imp(selector), YES);
		}
		else
		{
			const char *encoding = IoObjcBridge_selectorEncoding(DATA(self)->bridge, sel_getUid(CSTRING(slotName)));
			if (encoding)
			{
				SEL selector = sel_get_typed_uid(CSTRING(slotName), encoding);
				if (!selector) selector = sel_register_typed_name(CSTRING(slotName), encoding);
				class_addMethod(class, selector, encoding, __objc_get_forward_imp(selector), YES);
			}
			else
			{
				char *types = objc_malloc((argCount + 4) * sizeof(char));
				memset(types, '@', argCount + 3);
				types[argCount + 3] = 0;
				types[2] = ':';
				SEL selector = sel_get_typed_uid(CSTRING(slotName), types);
				if (!selector) selector = sel_register_typed_name(CSTRING(slotName), types);
				class_addMethod(class, selector, types, __objc_get_forward_imp(selector), YES);
				objc_free(types);
			}
		}
		{
			char *name = objc_malloc(2 + strlen(CSTRING(slotName)));
			name[0] = '-';
			name[1] = 0;
			IoSymbol *symbol = IoState_symbolWithCString_(IOSTATE, strcat(name, CSTRING(slotName)));
			objc_free(name);
			IoObject_inlineSetSlot_to_(self, symbol, slotValue);
		}
	}
	else
		IoObject_inlineSetSlot_to_(self, slotName, slotValue);
	return slotValue;
}

IoObject *Io2Objc_updateSlot(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	char *name = IoMessage_locals_cStringArgAt_(m, locals, 0);
	if (*name == '"') *(++name + strlen(name) - 1) = 0;
	IoSymbol *slotName = IOSYMBOL(name);
//	IoSymbol *slotName = IoMessage_locals_symbolArgAt_(m, locals, 0);
	IoObject *slotValue = IoMessage_locals_valueArgAt_(m, locals, 1);
	if (ISBLOCK(slotValue))
	{
		unsigned int argCount = IoMessage_argCount(slotValue);
		unsigned int expectedArgCount = 0;
		const char *name = CSTRING(slotName);
		while (*name) expectedArgCount += (*name++ == ':');
		if (argCount != expectedArgCount)
			IoState_error_(IOSTATE, m, "Method '%s' is waiting for %i arguments, %i given\n", CSTRING(slotName), expectedArgCount, argCount);
	}
	if (IoObject_rawGetSlot_(self, slotName))
		IoObject_inlineSetSlot_to_(self, slotName, slotValue);
	else
		IoState_error_(IOSTATE, m, "Slot %s not found. Must define slot using := operator before updating.", CSTRING(slotName));
	return slotValue;
}

IoObject *Io2Objc_super(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	IoMessage *message = List_at_(IOMESSAGEDATA(m)->args, 0);
	Class save = DATA(self)->object->isa;
	DATA(self)->object->isa = save->super_class;
	IoObject *result = Io2Objc_perform(self, locals, message);
	DATA(self)->object->isa = save;
	return result;
}

IoObject *Io2Objc_ioValue(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	id object = DATA(self)->object;
	if ([object isKindOfClass:[NSString class]])
		return IOSYMBOL((char *)[object cString]);
	else if ([object isKindOfClass:[NSNumber class]])
		return IONUMBER([object doubleValue]);
	else
		return IONIL(self);
}

/*IoObject *Io2Objc_print(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	printf("%s", [[DATA(self)->object description] cString]);
	return IONIL(self);
}*/

/*IoObject *Io2Objc_slotSummary(Io2Objc *self, IoObject *locals, IoMessage *m)
{
	int i;
	struct objc_method_list *methods;
	Class class = DATA(self)->object->isa;
	NSMutableSet *set = [[NSMutableSet alloc] initWithCapacity:32];
	while (class != nil)
	{
		void *iterator = 0;
		while ((methods = class_nextMethodList(class, &iterator)))
		{
			for (i = 0; i < methods->method_count; i++)
			{
				struct objc_method *method = &methods->method_list[i];
				if (method->method_name != 0)
				{
					NSString *name = [[NSString alloc] initWithUTF8String:sel_getName(method->method_name)];
					[set addObject:name];
					[name release];
				}
			}
		}
		class = class->super_class;
	}
	NSArray *array = [[set allObjects] sortedArrayUsingSelector:@selector(compare:)];
	[set release];
	for (i = 0; i < [array count]; i++) printf("%i: %s\n", i, [[[array objectAtIndex:i] description] cString]);
	return IONIL(self);
}*/
