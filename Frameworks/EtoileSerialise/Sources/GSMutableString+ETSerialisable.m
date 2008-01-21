#import "GSPrivate.h"
#import "ETSerialiser.h"
#import "ETDeserialiser.h"

#define CASE(x) if(strcmp(aVariable, #x) == 0)
#define STORE_FLAGS_AND_CONTENTS()\
	CASE(_flags)\
	{\
		return YES;\
	}\
	if(strcmp(aVariable, "_contents") == 0)\
	{\
		[[aSerialiser backend] storeInt:*(int*)&_flags withName:"_flags"];\
		[[aSerialiser backend] storeInt:*(int*)&_count withName:"_count"];\
		if(_flags.wide)\
		{\
			[[aSerialiser backend] storeData:_contents.u\
						 ofSize:sizeof(unichar) * (_count + 1)\
					   withName:"_contents"];\
		}\
		else\
		{\
			[[aSerialiser backend] storeData:_contents.c\
						 ofSize:sizeof(char) * (_count + 1)\
					   withName:"_contents"];\
		}\
		return YES;\
	}

#define ALLOC_STRING() \
	CASE(_contents)\
	{\
		if(_flags.wide)\
		{\
			_contents.u = calloc(_count+1, sizeof(unichar));\
			memcpy(_contents.u, aBlob, _count * sizeof(unichar));\
		}\
		else\
		{\
			_contents.c = calloc(_count+1, sizeof(char));\
			memcpy(_contents.u, aBlob, _count * sizeof(char));\
		}\
		_flags.free = 1;\
		return (void*)YES;\
	}
@implementation GSString (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(ETSerialiser*)aSerialiser
{
	STORE_FLAGS_AND_CONTENTS();
	return [super serialise:aVariable using:aSerialiser];
}
- (void*) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
{
	ALLOC_STRING();
	return (void*)NO;
}

@end

/**
 * Categories on GSMutableString to support serialisation.  
 */
@implementation GSMutableString (ETSerialisable)
/**
 * Store the flags (a bitfield) as a single integer and the _contents as a 
 * blob of data.
 */
- (BOOL) serialise:(char*)aVariable using:(ETSerialiser*)aSerialiser
{
	STORE_FLAGS_AND_CONTENTS();
	return [super serialise:aVariable using:aSerialiser];
}
//WARNING! Not endian-safe for unicode strings!
/**
 * Load the flags and correctly.
 */
- (void*) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
{
	ALLOC_STRING();
	CASE(_capacity)
	{
		_capacity = *(int*)aBlob;
		if(_capacity > _count)
		{
			_contents.c = realloc(_contents.c, _capacity);
		}
		else
		{
			_capacity = _count;
		}
	}
	return (void*)NO;
}
@end
