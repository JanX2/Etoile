#import "GSPrivate.h"
#import "ETSerializer.h"
#import "ETSerializerBackend.h"
#import "ETDeserializer.h"

#define CASE(x) if(strcmp(aVariable, #x) == 0)
#define STORE_FLAGS_AND_CONTENTS()\
NSLog(@"Serializing %s", aVariable);\
	if(strcmp(aVariable, "_contents") == 0)\
	{\
		[[aSerializer backend] storeInt:*(int*)&_flags withName:"_flags"];\
		[[aSerializer backend] storeInt:*(int*)&_count withName:"_count"];\
		if(_flags.wide)\
		{\
			[[aSerializer backend] storeData:_contents.u\
						 ofSize:sizeof(unichar) * (_count + 1)\
					   withName:"_contents"];\
		}\
		else\
		{\
			[[aSerializer backend] storeData:_contents.c\
						 ofSize:sizeof(char) * (_count)\
					   withName:"_contents"];\
		}\
	}\
	return YES;

#define ALLOC_STRING() \
	NSLog(@"Deserialising %s", aVariable);\
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
NSLog(@"Contents: %x, %d", _contents.u, _count);\
		_flags.free = 1;\
		return (void*)YES;\
	}
@implementation GSString (ETSerializable)
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	STORE_FLAGS_AND_CONTENTS();
	return [super serialize:aVariable using:aSerializer];
}
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
{
	ALLOC_STRING();
	return (void*)NO;
}

@end

/**
 * Categories on GSMutableString to support serialization.  
 */
@implementation GSMutableString (ETSerializable)
/**
 * Store the flags (a bitfield) as a single integer and the _contents as a 
 * blob of data.
 */
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	STORE_FLAGS_AND_CONTENTS();
	_zone = NSDefaultMallocZone();
	return [super serialize:aVariable using:aSerializer];
}
//WARNING! Not endian-safe for unicode strings!
/**
 * Load the flags and correctly.
 */
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
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
