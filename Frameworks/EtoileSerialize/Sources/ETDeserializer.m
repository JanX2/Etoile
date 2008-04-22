#import "ETDeserializer.h"
#import "ETDeserializerBackend.h"
//TODO: Move the things from here that I need into a shared header.
#import "ETSerializer.h"
#import "StringMap.h"

/**
 * Find the address of an named instance variable for an object.  This searches
 * through the list of instance variables in the class structure's ivars field.
 * Since this is a simple array, this search completes in O(n) time.  This can
 * not be improved upon without maintaining an external map of names to
 * instance variables.
 */
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
		//If the instance variable is not from this class, check the superclass.
		class = class->super_class;
	}
	return NULL;
}

/**
 * This protocol defines the -finishedDeserializing method.  It is private to
 * this file, and only exists to prevent a compiler warning that the selector
 * is not defined anywhere.  This is not done as a category on NSObject to
 * allow run-time checking of whether the object implements the method to work.  
 */
@protocol _COAwareObject
- (void) finishedDeserializing;
@end

/**
 * Macro used to store an object reference to pointer mapping.
 */
#define SET_REF(ref, obj) NSMapInsert(loadedObjects, (void*)ref, (void*) obj)
/**
 * Macro to retrieve a pointer from an object reference.
 */
#define GET_OBJ(ref) (id)NSMapGet(loadedObjects, (void*)ref)
//TODO: Add bounds checking to this and some overflow capability
//for stupidly nested objects.
/**
 * Macro defining the top state on our state stack.
 */
#define STATE states[stackTop]
/**
 * Push a new state onto the stack.  Takes the offset at which instance
 * variables are written and the state as arguments.
 */
#define PUSH_STATE(offset, stateType) ++stackTop;STATE.startOffset = offset; STATE.size = 0; STATE.type = stateType; STATE.index = loadedIVar; loadedIVar = 0;//NSLog(@"Pushing state '%c', starting at %d\n", stateType, (int)offset - (int)object);
/**
 * Push a state indicating that we are deserializing a structure onto the stack.
 */
#define PUSH_STRUCT(offset) PUSH_STATE(offset, 's')
/**
 * Push a state indicating that we are deserializing a structure with a custom
 * deserializer onto the stack.
 */
#define PUSH_CUSTOM(offset) PUSH_STATE(offset, 'c');STATE.index = (int)function
/**
 * Push a state indicating that we are deserializing an array onto the stack.
 */
#define PUSH_ARRAY(offset) PUSH_STATE(offset, 'a')
/**
 * Pop the top state from the stack.
 */
#define POP() states[stackTop-1].startOffset += states[stackTop].size; loadedIVar = states[stackTop--].index;

/**
 * Category on ETDeserializer for storing a pointer to an object that should be
 * set later, after the object is loaded.  This is used by
 * ETInvocationDeserializer for object pointers loaded in arguments.
 */
@interface ETDeserializer (RegisterObjectPointer)
/**
 * Register that aPointer the value of is a pointer to the object referenced by
 * anObject.
 */
- (void) registerPointer:(id*)aPointer forObject:(CORef)anObject;
@end
@implementation ETDeserializer (RegisterObjectPointer)
- (void) registerPointer:(id*)aPointer forObject:(CORef)anObject
{
	NSMapInsert(objectPointers, aPointer, (void*)anObject);
}
@end

/**
 * Macro for calling offsetOfIvar with some default arguments.
 */
#define OFFSET_OF_IVAR(object, name, hint, type) offsetOfIvar(object, name, hint, sizeof(type), stackTop, &STATE)

/**
 * Find the offset of a variable to be loaded.  In the top state this finds an
 * instance variable.  If a structure or array state is on the top of the stack
 * then this will return the address of the next element in the structure or
 * array instead.
 *
 * Addresses for elements structures with a custom deserializer should be
 * determined by the custom deserializer, not this function.
 */
inline static void * offsetOfIvar(id anObject, char * aName, int hint, int size, int stackTop, ETDeserializerState * state)
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
			//In an array
			case 'a':
				{
					state->size = size * (hint);
					return state->startOffset + size * hint;
				}
			//In a structure
			case 's':
				{
					void * offset = state->startOffset;
					state->startOffset += size;
					state->size += size;
					while((int)state->startOffset % __alignof__(int) != 0)
					{
						state->startOffset++;
						state->size++;
					}
					return offset;
				}
			//Called for a state we don't know about.
			default:
				{
					NSLog(@"Invalid state '%c'!  No skill!", state->type);\
				}
		}
		return NULL;
	}
}

/**
 * Map of structure names to functions registered for deserializing them.
 */
static NSMapTable * deserializerFunctions;

/**
 * ETInvocationDeserializer is a private class used for deserializing
 * NSInvocations and their subclasses.  This is a horrible hack, which is
 * needed since invocations store their data in a way that is not easily
 * accessible by the standard mechanisms.  Invocation objects store their
 * arguments in a C stack frame, which is not easy for the deserializer to
 * load.  In order to re-create the stack frame, the NSMethodSignature object
 * must have already been loaded.  This is typically not the case, so some
 * patchwork is required.  This class caches the arguments in a buffer.  Once
 * the arguments have been loaded, it calls the invocation's
 * -initWithMethodSignature: method, which re-creates the stack frame (using
 *  FFCall or libFFI).  It then sets the arguments using -setArgument:atIndex:.  
 *
 * This is not a wonderful solution.  If anyone can think of a better one,
 * please let me know.
 */
@interface ETInvocationDeserializer : ETDeserializer {
	/** The deserializer that created this object. */
	ETDeserializer * realDeserializer;
	/** The number of arguments we expect to load. */
	int argCount;
	/** An array of pointers to the arguments. */
	void ** args;
	/** The buffer in which we load the arguments. */
	void * stackFrame;
	/** The address to which we write the next argument. */
	char * nextArg;
}
/**
 * Initialise a newly created invocation deserializer loading an already
 * +alloc'd invocation with the specified number of arguments.
 */
- (id) initWithDeserializer:(ETDeserializer*)aDeserializer 
			  forInvocation:(id)anInvocation
			   withArgCount:(int)anInt;
/**
 * Initialise the invocation and set the arguments.
 */
- (void) setupInvocation;
@end
@implementation ETInvocationDeserializer
- (void) dealloc
{
	free(args);
	free(stackFrame);
	[super dealloc];
}
- (id) initWithDeserializer:(ETDeserializer*)aDeserializer 
			  forInvocation:(id)anInvocation
			   withArgCount:(int)anInt
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	argCount = anInt;
	args = calloc(anInt, sizeof(void*));
	//FIXME: Dynamically resize this.  Note:  Doing this will require some
	//modification to the way in which pointers to objects are registered if
	//realloc ever needs to move the original allocation.
	stackFrame = calloc(1024,1);
	nextArg = stackFrame;
	object = anInvocation;
	//aDeserializer ought to have a longer life cycle than us.
	realDeserializer = aDeserializer;
	return self;
}
- (void) endObject 
{
	[backend setDeserializer:realDeserializer];
	[realDeserializer endObject];
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
#define CUSTOM_DESERIALIZER ((custom_deserializer)STATE.index)
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
		nextArg = CUSTOM_DESERIALIZER(aName, &aVal, nextArg);\
	}
#define LOAD_INTRINSIC(type, name) \
{\
	IS_NEW_ARG(name);\
	CHECK_CUSTOM()\
	if(![object deserialize:name fromPointer:&aVal version:classVersion])\
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
		[realDeserializer registerPointer:address forObject:aReference];
	}
	ADD_ARG(id, nil);
}
//Nested types
- (void) beginStruct:(char*)aStructName withName:(char*)aName
{
	IS_NEW_ARG(aName);
	//FIXME: We want some way of determining the size of the data
	//Try using a registered decoder function.
	custom_deserializer function = NSMapGet(deserializerFunctions, aStructName);
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
		STATE.startOffset = CUSTOM_DESERIALIZER(aName, aCString, STATE.startOffset);
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
		STATE.startOffset = CUSTOM_DESERIALIZER(aName, aBlob, STATE.startOffset);
	}
	else if(![object deserialize:aName fromPointer:aBlob version:classVersion])
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

/**
 * The deserializer is responsible for creating objects from a stream of (name,
 * type, value) tuples supplied as messages from the back end.
 */
@implementation ETDeserializer
/**
 * Allocate the custom deserializer mapping structure.
 */
+ (void) initialize
{
	[super initialize];
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	deserializerFunctions = NSCreateMapTable(STRING_MAP_KEY_CALLBACKS, valuecallbacks, 100);
	/* Custom serializers for known types */
}
+ (void) registerDeserializer:(custom_deserializer)aDeserializer forStructNamed:(char*)aName
{
	NSMapInsert(deserializerFunctions, aName, (void*)aDeserializer);
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
- (void) setBackend:(id<ETDeserializerBackend>)aBackend
{
	ASSIGN(backend, aBackend);
	[backend setDeserializer:self];
}
+ (ETDeserializer*) deserializerWithBackend:(id<ETDeserializerBackend>)aBackend
{
	ETDeserializer * deserializer = [[[self alloc] init] autorelease];
	[deserializer setBackend:aBackend];
	return deserializer;
}
- (void) setClassVersion:(int)aVersion
{
	classVersion = aVersion;
}
- (BOOL) setBranch:(NSString*)aBranch
{
	return [backend setBranch:aBranch];
}
- (int) setVersion:(int)aVersion
{
	return [backend setVersion:aVersion];
}
/**
 * Load the principle object from the back end.  Doing this may involve loading
 * some object pointers that point to objects that are not yet loaded.  If it
 * does, load the referenced objects, and set up the pointers to point to the
 * correct location.  Repeat this until there are no unresolved pointers.
 *
 * Once all objects in the graph are loaded, call the -finishedDeserializing
 * method in any objects that implement it.
 */
- (id) restoreObjectGraph
{
	CORef mainObject = [backend principalObject];
	[backend deserializeObjectWithID:mainObject];
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
			[backend deserializeObjectWithID:ref];
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
		[finishedObject finishedDeserializing];
	}
	[loadedObjectList removeAllObjects];
	//Fix up invocations with some hacks.
	[invocations makeObjectsPerformSelector:@selector(setupInvocation)];
	return GET_OBJ(mainObject);
}
//Objects
/**
 * Begin loading an object.  Allocate space for it, and then add subsequent
 * values as instance variables.  If this is an invocation, set up some special
 * handling.
 */
- (void) beginObjectWithID:(CORef)aReference withClass:(Class)aClass 
{
	loadedIVar = 0;
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
/**
 * Finish loading an object.  If it responds to the -finishedDeserializing
 * selector then call this later.
 */
- (void) endObject 
{
	if(class_get_instance_method(object->class_pointer, @selector(finishedDeserializing)))
	{
		[loadedObjectList addObject:object];
	}
}
/**
 * If we are loading a structure with a custom deserializer function then call
 * this function.
 */
#define CHECK_CUSTOM() \
	if(STATE.type == 'c')\
	{\
		STATE.startOffset = CUSTOM_DESERIALIZER(aName, &aVal, STATE.startOffset);\
	}

/**
 * Load an intrinsic by looking up its address and copying the value.
 */
#define LOAD_INTRINSIC(type, name) \
{\
	CHECK_CUSTOM()\
	else if(![object deserialize:aName fromPointer:&aVal version:classVersion])\
	{\
		char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, type);\
		if(address != NULL)\
		{\
			*(type*)address = aVal;\
		}\
	}\
}
/**
 * Load an object reference.  If we have already loaded this object, just set
 * the pointer to the correct value, otherwise record this and come back to it
 * later.
 */
- (void) loadObjectReference:(CORef)aReference withName:(char*)aName
{
	id * address = [object deserialize:aName fromPointer:&aName version:classVersion];
	switch((long)address)
	{
		case YES:
			break;
		case NO:
			address = OFFSET_OF_IVAR(object, aName, loadedIVar++, id);
		default:
			if(address != NULL)
			{
				if(aReference != 0)
				{
					id aVal = GET_OBJ(aReference);
					if(aVal != nil)
					{
						*address = aVal;
					}
					else
					{
						//NSLog(@"Storing 0x%x as address of %d", address, aReference);
						NSMapInsert(objectPointers, address, (void*)aReference);
					}
				}
				else
				{
					*(id*)address = nil;
				}
			}
	}
}
/**
 * Set the retain count for a newly loaded object.
 */
- (void) setReferenceCountForObject:(CORef)anObjectID to:(int)aRefCount 
{
	id obj = GET_OBJ(anObjectID);
	while(aRefCount-- > 1)
	{
		RETAIN(obj);
	}
}
//Nested types
/**
 * Begin deserializing a structure.  An object may allocate space for the
 * structure with its custom method, and provide an alternate location to load
 * the fields, if it wishes.
 */
- (void) beginStruct:(char*)aStructName withName:(char*)aName;
{
	char * address = offsetOfIvar(object, aName, loadedIVar++, 0, stackTop, &STATE);
	//First see if the object wants to change the offset (e.g. loading a pointer)
	char * fudgedAddress = [object deserialize:aName fromPointer:NULL version:classVersion];
	//NSLog(@"Fudged address for %s is 0x%x", aName, fudgedAddress);
	switch((int)fudgedAddress)
	{
		case (int)MANUAL_DESERIALIZE:
			{
				NSLog(@"ERROR:  Invalid return for deserializing struct");
				break;
			}
		case (int)AUTO_DESERIALIZE:
			break;
		default:
			//Set the address to the one the class wants (for malloc'd data structures, etc)
			address = fudgedAddress;
	}
	//Try using a registered decoder function.
	custom_deserializer function = NSMapGet(deserializerFunctions, aStructName);
	if(function != NULL)
	{
		char * address = offsetOfIvar(object, aName, loadedIVar++, 0, stackTop, &STATE);
		PUSH_CUSTOM(address);
	}
	else
	{
		//NSLog(@"Struct address = 0x%x", address);
		if(address != NULL)
		{
			PUSH_STRUCT(address);
		}
	}
}
/**
 * End a structure by popping the 'in structure' state from the top of the
 * stack.
 */
- (void) endStruct 
{
	POP();
}
/**
 * Begin loading an array.
 */
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength
{
	//FIXME: This should do the same fudging as beginStruct:withName:
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
/**
 * Macro used to define a method for loading an intrinsic.
 */
#define LOAD_METHOD(name, type) - (void) load ## name:(type)aVal withName:(char*)aName LOAD_INTRINSIC(type, name)
LOAD_METHOD(Char, char)
LOAD_METHOD(UnsignedChar, unsigned char)
LOAD_METHOD(Short, short)
LOAD_METHOD(UnsignedShort, unsigned short)
/**
 * Load an integer.  Contains a special case for loading the number of
 * arguments in an invocation, causing it to vector off into the custom
 * invocation deserializer.
 */
- (void) loadInt:(int)aVal withName:(char*)aName
{
	if(
	    isInvocation
		&&
		strcmp(aName, "numberOfArguments") == 0
	  )
	{
		id inv = [[ETInvocationDeserializer alloc] initWithDeserializer:self
		                                                  forInvocation:object
		                                                   withArgCount:(int)aVal];
		[inv setBackend:backend];
		[invocations addObject:inv];
		[inv release];
		[backend setDeserializer:inv];
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
		STATE.startOffset = CUSTOM_DESERIALIZER(aName, aCString, STATE.startOffset);
	}
	else if(![object deserialize:aName fromPointer:aCString version:classVersion])
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
		STATE.startOffset = CUSTOM_DESERIALIZER(aName, aBlob, STATE.startOffset);
	}
	else if(![object deserialize:aName fromPointer:aBlob version:classVersion])
	{
		char * address = OFFSET_OF_IVAR(object, aName, loadedIVar++, aSize);
		if(address != NULL)
		{
			memcpy(address, aBlob, aSize);
		}
	}
}

- (void) loadUUID: (char *)anUUID withName: (char *)aName
{
	NSLog(@"Load UUID %s to name %s", anUUID, aName);
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
