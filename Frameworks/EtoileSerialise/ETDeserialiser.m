#import "ETDeserialiser.h"
//TODO: Move the things from here that I need into a shared header.
#import "ETSerialiser.h"
#import "StringMap.h"

inline static void * addressForIVarName(id anObject, char * aName, int hint)
{
	//Find a real iVar
	Class class = anObject->class_pointer;
	while(class != Nil && class != class->super_class)
	{
		struct objc_ivar_list* ivarlist = class->ivars;
		if(ivarlist != NULL) 
		{
			for(int i=0 ; i<ivarlist->ivar_count ; i++)
			{
				char * name = (char*)ivarlist->ivar_list[i].ivar_name;
				if(strcmp(aName, name) == 0)
				{
					return ((char*)anObject + (ivarlist->ivar_list[i].ivar_offset));
				}
			}
		}
		class = class->super_class;
	}
	return NULL;
}

@protocol _COAwareObject
- (void) finishedDeserialising;
@end

#define SET_REF(ref, obj) NSMapInsert(loadedObjects, (void*)ref, (void*) obj)
#define GET_OBJ(ref) (id)NSMapGet(loadedObjects, (void*)ref)
//TODO: Add bounds checking to this and some overflow capability
//for stupidly nested objects.
#define STATE states[stackTop]
#define PUSH_STATE(offset, stateType) ++stackTop;STATE.startOffset = offset; STATE.type = stateType; STATE.index = loadedIVar; loadedIVar = 0;// NSLog(@"Pushing state '%c'", stateType);
#define PUSH_STRUCT(offset) PUSH_STATE(offset, 's')
#define PUSH_CUSTOM(offset) PUSH_STATE(offset, 'c');STATE.index = (int)function
#define PUSH_ARRAY(offset) PUSH_STATE(offset, 'a')
#define POP() loadedIVar = states[stackTop--].index;

@interface ETDeserialiser (RegisterObjectPointer)
- (void) registerPointer:(id*)aPointer forObject:(CORef)anObject;
@end
@implementation ETDeserialiser (RegisterObjectPointer)
- (void) registerPointer:(id*)aPointer forObject:(CORef)anObject
{
	NSMapInsert(objectPointers, aPointer, (void*)anObject);
}
@end
#define OFFSET_OF_IVAR(object, name, hint, type) offsetOfIvar(object, name, hint, sizeof(type), stackTop, &STATE)

inline static void * offsetOfIvar(id anObject, char * aName, int hint, int size, int stackTop, ETDeserialiserState * state)
{
	if(stackTop == 0)
	{
		return addressForIVarName(anObject, aName, hint);
	}
	else
	{
		//NSLog(@"Inside nested type looking for %s.", aName);
		switch(state->type)
		{
			case 'a':
				{
					return state->startOffset + size * hint;
				}
			case 's':
				{
					//TODO: Make this alignment-aware
					void * offset = state->startOffset;
					state->startOffset += size;
					while((int)state->startOffset % __alignof__(int) != 0)
					{
						state->startOffset++;
					}
					return offset;
				}
			default:
				{
					NSLog(@"Invalid state '%c'!  No skill!", state->type);\
				}
		}
		return NULL;
	}
}

static NSMapTable * deserialiserFunctions;

@interface ETInvocationDeserialiser : ETDeserialiser {
	ETDeserialiser * realDeserialiser;
	int argCount;
	void ** args;
	void * stackFrame;
	char * nextArg;
}
- (id) initWithDeserialiser:(ETDeserialiser*)aDeserialiser 
			  forInvocation:(id)anInvocation
			   withArgCount:(int)anInt;
- (void) setupInvocation;
@end
@implementation ETInvocationDeserialiser
- (void) dealloc
{
	free(args);
	free(stackFrame);
	[super dealloc];
}
- (id) initWithDeserialiser:(ETDeserialiser*)aDeserialiser 
			  forInvocation:(id)anInvocation
			   withArgCount:(int)anInt
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	argCount = anInt;
	args = calloc(anInt, sizeof(void*));
	stackFrame = calloc(1024,1);
	nextArg = stackFrame;
	object = anInvocation;
	//aDeserialiser ought to have a longer life cycle than us.
	realDeserialiser = aDeserialiser;
	return self;
}
- (void) endObject 
{
	[backend setDeserialiser:realDeserialiser];
	[realDeserialiser endObject];
}
- (void) setupInvocation
{
	//FIXME: This probably leaks memory. 
	//Use some proper skill to find out where.

	//Set up the stack frame again
	NSMethodSignature * sig = [object methodSignature];
	[object initWithMethodSignature:sig];
	//Re-add the arguments (0 and 1 are self and cmd)
	for(int i=2 ; i<argCount ; i++)
	{
		//NSLog(@"Setting argument %d to 0x%x", i, args[i]);
		[object setArgument:args[i] atIndex:i];
	}
	//Invocation now has two references to method signature.
	[sig release];
}
#define CUSTOM_DESERIALISER ((custom_deserialiser)STATE.index)
#define IS_NEW_ARG(name) \
	if(strncmp("arg.", name, 4) == 0)\
	{\
		args[name[4] - 060] = nextArg;\
	}
//TODO: Resize the frame if I need it.
//TODO: Alignment stuff for structs
#define ADD_ARG(type, arg) \
	*(type*)nextArg = arg;\
	nextArg += sizeof(type);
#define CHECK_CUSTOM() \
	if(STATE.type == 'c')\
	{\
		nextArg = CUSTOM_DESERIALISER(aName, &aVal, nextArg);\
	}
#define LOAD_INTRINSIC(type, name) \
{\
	IS_NEW_ARG(name);\
	CHECK_CUSTOM()\
	if(![object deserialise:name fromPointer:&aVal version:classVersion])\
	{\
		ADD_ARG(type, aVal);\
	}\
}
//Callbacks
- (void) loadObjectReference:(CORef)aReference withName:(char*)aName
{
	IS_NEW_ARG(aName);
	id * address = (id*)nextArg;
	if(aReference != 0)
	{
		[realDeserialiser registerPointer:address forObject:aReference];
	}
	ADD_ARG(id, nil);
}
//Nested types
- (void) beginStruct:(char*)aStructName withName:(char*)aName
{
	IS_NEW_ARG(aName);
	//FIXME: We want some way of determining the size of the data
	//Try using a registered decoder function.
	custom_deserialiser function = NSMapGet(deserialiserFunctions, aStructName);
	if(function != NULL)
	{
		PUSH_CUSTOM(nextArg);
	}
	else
	{
		PUSH_STRUCT(nextArg);
	}
}
- (void) endStruct 
{
	POP();
}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength
{
	IS_NEW_ARG(aName);
	if(stackTop == 0)
	{
		int i = aName[4] - 060;
		args[i] = malloc(aLength);
	}
	char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, aLength);

	if(address != NULL)
	{
		PUSH_ARRAY(address);
	}
}
- (void) endArray 
{
	POP();
}
//Intrinsics
#define LOAD_METHOD(name, type) - (void) load ## name:(type)aVal withName:(char*)aName LOAD_INTRINSIC(type, aName)
LOAD_METHOD(Char, char)
LOAD_METHOD(UnsignedChar, unsigned char)
LOAD_METHOD(Short, short)
LOAD_METHOD(UnsignedShort, unsigned short)
LOAD_METHOD(Int, int)
LOAD_METHOD(UnsignedInt, unsigned int)
LOAD_METHOD(Long, long)
LOAD_METHOD(UnsignedLong, unsigned long)
LOAD_METHOD(LongLong, long long)
LOAD_METHOD(UnsignedLongLong, unsigned long long)
LOAD_METHOD(Float, float)
LOAD_METHOD(Double, double)
LOAD_METHOD(Class, Class)
LOAD_METHOD(Selector, SEL)
- (void) loadCString:(char*)aCString withName:(char*)aName
{
	if(STATE.type == 'c')
	{
		STATE.startOffset = CUSTOM_DESERIALISER(aName, aCString, STATE.startOffset);
	}
	else 
	{
		char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, sizeof(char*));
		if(address != NULL)
		{
			*(char**)address = strdup(aCString);
		}
	}
}
- (void) loadData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName 
{
	if(STATE.type == 'c')
	{
		STATE.startOffset = CUSTOM_DESERIALISER(aName, aBlob, STATE.startOffset);
	}
	else if(![object deserialise:aName fromPointer:aBlob version:classVersion])
	{
		char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, aSize);
		if(address != NULL)
		{
			memcpy(address, aBlob, aSize);
		}
	}
}
#undef LOAD_METHOD
#undef LOAD_INTRINSIC
#undef CHECK_CUSTOM
@end

@implementation ETDeserialiser
+ (void) initialize
{
	[super initialize];
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	deserialiserFunctions = NSCreateMapTable(STRING_MAP_KEY_CALLBACKS, valuecallbacks, 100);
	/* Custom serialisers for known types */
}
+ (void) registerDeserialiser:(custom_deserialiser)aDeserialiser forStructNamed:(char*)aName
{
	NSMapInsert(deserialiserFunctions, aName, (void*)aDeserialiser);
}
- (id) init
{
	if(nil == (self = [super init]))
	{
		return nil;
	}
	const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	//TODO: After we've got some real profiling data, 
	//change 100 to a more sensible value
	loadedObjects = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	objectPointers = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	loadedObjectList = [[NSMutableArray alloc] init];
	invocations = [[NSMutableArray alloc] init];
	return self;
}
- (void) setBackend:(id<ETDeserialiserBackend>)aBackend
{
	ASSIGN(backend, aBackend);
	[backend setDeserialiser:self];
}
+ (ETDeserialiser*) deserialiserWithBackend:(id<ETDeserialiserBackend>)aBackend
{
	ETDeserialiser * deserialiser = [[[ETDeserialiser alloc] init] autorelease];
	[deserialiser setBackend:aBackend];
	return deserialiser;
}
- (void) setClassVersion:(int)aVersion
{
	classVersion = aVersion;
}
- (id) restoreObjectGraph
{
	CORef mainObject = [backend principalObject];
	[backend deserialiseObjectWithID:mainObject];
	//Also restore referenced objects
	NSMapEnumerator enumerator = NSEnumerateMapTable(objectPointers);
	CORef ref;
	id * pointer;
	while(NSNextMapEnumeratorPair(&enumerator, (void*)&pointer, (void*)&ref))
	{
		//NSLog(@"Setting pointer at 0x%x to 0x%x for ref %d", pointer, GET_OBJ(ref), ref);
		*pointer = GET_OBJ(ref);
		//If we haven't already loaded this object, then do.
		if(*pointer == NULL)
		{
			[backend deserialiseObjectWithID:ref];
			//NSLog(@"Setting pointer at 0x%x to 0x%x for ref %d", pointer, GET_OBJ(ref), ref);
			*pointer = GET_OBJ(ref);
		}
		NSMapRemove(objectPointers, pointer);
		//Restart the enumeration
		NSEndMapTableEnumeration(&enumerator);
		enumerator = NSEnumerateMapTable(objectPointers);
	}
	NSEnumerator * finishedEnumerator = [loadedObjectList objectEnumerator];
	id finishedObject;
	while((finishedObject = [finishedEnumerator nextObject]) != nil)
	{
		[finishedObject finishedDeserialising];
	}
	[loadedObjectList removeAllObjects];
	//Fix up invocations with some hacks.
	[invocations makeObjectsPerformSelector:@selector(setupInvocation)];
	return GET_OBJ(mainObject);
}
//Objects
- (void) beginObjectWithID:(CORef)aReference withClass:(Class)aClass 
{
	loadedIVar = 0;
	//TODO: Decide if this should call init.  Probably not...
	object = [aClass alloc];
	//NSLog(@"Loading %@ at address 0x%x for ref %d", [aClass className], object, aReference);
	SET_REF(aReference, object);
	if([object isKindOfClass:[NSInvocation class]])
	{
		isInvocation = YES;
	}
	else
	{
		isInvocation = NO;
	}
}
- (void) endObject 
{
	if(class_get_instance_method(object->class_pointer, @selector(finishedDeserialising)))
	{
		[loadedObjectList addObject:object];
	}
}
#define CHECK_CUSTOM() \
	if(STATE.type == 'c')\
	{\
		STATE.startOffset = CUSTOM_DESERIALISER(aName, &aVal, STATE.startOffset);\
	}

#define LOAD_INTRINSIC(type, name) \
{\
	CHECK_CUSTOM()\
	else if(![object deserialise:aName fromPointer:&aVal version:classVersion])\
	{\
		char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, type);\
		if(address != NULL)\
		{\
			*(type*)address = aVal;\
		}\
	}\
}
- (void) loadObjectReference:(CORef)aReference withName:(char*)aName
{
	if(![object deserialise:aName fromPointer:&aName version:classVersion])
	{
		if(aReference != 0)
		{
			id aVal = GET_OBJ(aReference);
			if(aVal != nil)
			{
				LOAD_INTRINSIC(id, aName);
			}
			else
			{
				void * pointer = OFFSET_OF_IVAR(object, aName, loadedIVar++, id);
				NSMapInsert(objectPointers, pointer, (void*)aReference);
			}
		}
		else
		{
			char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, id);
			if(address != NULL)
			{
				*(id*)address = nil;
			}
		}
	}
}
- (void) setReferenceCountForObject:(CORef)anObjectID to:(int)aRefCount 
{
	id obj = GET_OBJ(anObjectID);
	while(aRefCount-- > 1)
	{
		RETAIN(obj);
	}
}
//Nested types
- (void) beginStruct:(char*)aStructName withName:(char*)aName;
{
	char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, 10);
	//First see if the object wants to change the offset (e.g. loading a pointer)
	char * fudgedAddress = [object deserialise:aName fromPointer:NULL version:classVersion];
	//NSLog(@"Fudged address for %s is 0x%x", aName, fudgedAddress);
	switch((int)fudgedAddress)
	{
		case (int)MANUAL_DESERIALISE:
			{
				NSLog(@"ERROR:  Invalid return for deserialising struct");
				break;
			}
		case (int)AUTO_DESERIALISE:
			break;
		default:
			//Set the address to the one the class wants (for malloc'd data structures, etc)
			address = fudgedAddress;
	}
	//Try using a registered decoder function.
	custom_deserialiser function = NSMapGet(deserialiserFunctions, aStructName);
	if(function != NULL)
	{
		char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, 10);
		PUSH_CUSTOM(address);
	}
	else
	{
		//TODO: Change this 10 to something correct
		//NSLog(@"Struct address = 0x%x", address);
		if(address != NULL)
		{
			PUSH_STRUCT(address);
		}
	}
}
- (void) endStruct 
{
	POP();
}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength
{
	char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, aLength);

	if(address != NULL)
	{
		PUSH_ARRAY(address);
	}
}
- (void) endArray 
{
	POP();
}
//Intrinsics
#define LOAD_METHOD(name, type) - (void) load ## name:(type)aVal withName:(char*)aName LOAD_INTRINSIC(type, name)
LOAD_METHOD(Char, char)
LOAD_METHOD(UnsignedChar, unsigned char)
LOAD_METHOD(Short, short)
LOAD_METHOD(UnsignedShort, unsigned short)
- (void) loadInt:(int)aVal withName:(char*)aName
{
	if(
	    isInvocation
		&&
		strcmp(aName, "numberOfArguments") == 0
	  )
	{
		id inv = [[ETInvocationDeserialiser alloc] initWithDeserialiser:self
		                                                  forInvocation:object
		                                                   withArgCount:(int)aVal];
		[inv setBackend:backend];
		[invocations addObject:inv];
		[inv release];
		[backend setDeserialiser:inv];
	}
	else
	{
		LOAD_INTRINSIC(int, name);
	}
}
LOAD_METHOD(UnsignedInt, unsigned int)
LOAD_METHOD(Long, long)
LOAD_METHOD(UnsignedLong, unsigned long)
LOAD_METHOD(LongLong, long long)
LOAD_METHOD(UnsignedLongLong, unsigned long long)
LOAD_METHOD(Float, float)
LOAD_METHOD(Double, double)
LOAD_METHOD(Class, Class)
LOAD_METHOD(Selector, SEL)
- (void) loadCString:(char*)aCString withName:(char*)aName
{
	if(STATE.type == 'c')
	{
		STATE.startOffset = CUSTOM_DESERIALISER(aName, aCString, STATE.startOffset);
	}
	else if(![object deserialise:aName fromPointer:aCString version:classVersion])
	{
		char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, sizeof(char*));
		if(address != NULL)
		{
			*(char**)address = strdup(aCString);
		}
	}
}
- (void) loadData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName 
{
	if(STATE.type == 'c')
	{
		STATE.startOffset = CUSTOM_DESERIALISER(aName, aBlob, STATE.startOffset);
	}
	else if(![object deserialise:aName fromPointer:aBlob version:classVersion])
	{
		char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, aSize);
		if(address != NULL)
		{
			memcpy(address, aBlob, aSize);
		}
	}
}

- (void) dealloc
{
	NSFreeMapTable(loadedObjects);
	[backend release];
	[loadedObjectList release];
	[invocations release];
	[super dealloc];
}
@end
