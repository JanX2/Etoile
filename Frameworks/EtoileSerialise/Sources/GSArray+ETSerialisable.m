#import "GSPrivate.h"
#import "ETSerialiser.h"
#import "ETDeserialiser.h"

#define CASE(x) if(strcmp(aVariable, #x) == 0)
#define serialiseUsing()\
{\
	CASE(_contents_array)\
	{\
		id back = [aSerialiser backend];\
		/* Cheat and store the count in the wrong order */\
		[back storeUnsignedInt:_count withName:"_count"];\
		for(unsigned int i=0 ; i<_count ; i++)\
		{\
			char * saveName;\
			asprintf(&saveName, "_contents_array.%d", i);\
			[back storeObjectReference:COREF_FROM_ID(_contents_array[i]) withName:saveName];\
			[aSerialiser enqueueObject:_contents_array[i]];\
			free(saveName);\
		}\
		return YES;\
	}\
	CASE(_count)\
	{\
		return YES;\
	}\
	return [super serialise:aVariable using:aSerialiser];\
}
#define deserialiseFromPointer()\
{\
	CASE(_count)\
	{\
		_contents_array = calloc(*(unsigned*)aBlob, sizeof(id));\
	}\
	int index;\
	if(sscanf(aVariable, "_contents_array.%d", &index) == 1)\
	{\
		NSAssert(_count, @"Can't deserialise data before array size in GSArray");\
		return &_contents_array[index];\
	}\
	return [super deserialise:aVariable fromPointer:aBlob version:aVersion];\
}
/**
 * Category for correctly serialising array objects.
 */
@implementation GSArray (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(ETSerialiser*)aSerialiser
{
	serialiseUsing();
}
- (void*) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	deserialiseFromPointer();
}
@end
@implementation GSMutableArray (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(ETSerialiser*)aSerialiser
{
	serialiseUsing();
}
- (void*) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	deserialiseFromPointer();
}
- (void) finishedDeserialising
{
	if(_capacity != _count)
	{
		_contents_array = realloc(_contents_array, _capacity * sizeof(id));
	}
}
@end
