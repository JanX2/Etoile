#import "ETDeserialiser.h"

inline static void * addressForIVarName(id anObject, char * aName, int hint)
{
	struct objc_ivar_list* ivarlist = anObject->class_pointer->ivars;
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
	return NULL;
}

@protocol _COAwareObject
- (void) finishedDeserialising;
@end

#define SET_REF(ref, obj) NSMapInsert(loadedObjects, (void*)ref, (void*) obj)
#define GET_OBJ(ref) (id)NSMapGet(loadedObjects, (void*)ref)
@implementation ETDeserialiser
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
	return self;
}
- (void) setBackend:(id<ETDeserialiserBackend>)aBackend
{
	backend = [aBackend retain];
	[backend setDeserialiser:self];
}
+ (ETDeserialiser*) deserialiserWithBackend:(id<ETDeserialiserBackend>)aBackend
{
	ETDeserialiser * deserialiser = [[[ETDeserialiser alloc] init] autorelease];
	[deserialiser setBackend:aBackend];
	return deserialiser;
}
- (id) restoreObjectGraph
{
	CORef mainObject = [backend principalObject];
	//TODO: Also restore referenced objects
	[backend deserialiseObjectWithID:mainObject];
	NSLog(@"Deserialising %d", mainObject);
	return GET_OBJ(mainObject);
}
//Objects
- (void) beginObjectWithID:(CORef)aReference withClass:(Class)aClass 
{
	//TODO: Decide if this should call init.  Probably not...
	object = [aClass alloc];
	SET_REF(aReference, object);
	NSLog(@"Restored {%d, %d}", aReference, object);
}
- (void) endObject 
{
	//TODO: Call using the returned IMP
	if(class_get_instance_method(object->class_pointer, @selector(finishedDeserialising)))
	{
		[object finishedDeserialising];
	}
}
#define LOAD_INTRINSIC(type, name) \
{\
	char * address = addressForIVarName(object, aName, loadedIVar++);\
	if(address != NULL)\
	{\
		*(type*)address = aVal;\
	}\
}
- (void) loadObjectReference:(CORef)aReference withName:(char*)aName
{
	if(aReference != 0)
	{
		id aVal = GET_OBJ(aReference);
		if(aVal != nil)
		{
			LOAD_INTRINSIC(id, aName);
		}
	}
	else
	{
		NSLog(@"Set %s to %d after deserialising", aName, aReference);
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
- (void) beginStructNamed:(char*)aName {}
- (void) endStruct {}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength {}
- (void) endArray {}
//Intrinsics
#define LOAD_METHOD(name, type) - (void) load ## name:(type)aVal withName:(char*)aName LOAD_INTRINSIC(type, name)
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
	char * address = addressForIVarName(object, aName, loadedIVar++);
	if(address != NULL)
	{
		*(char**)address = strdup(aCString);
	}
}
- (void) loadData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName {}

- (void) dealloc
{
	NSFreeMapTable(loadedObjects);
	[backend release];
	[super dealloc];
}
@end
