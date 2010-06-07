#import "ETSerializer.h"
#import "ETSerializerBackend.h"
#import "ETDeserializer.h"

// From GNUstep:
@interface GSArray : NSArray
{
@public
	id       *_contents_array;
	unsigned  _count;
}
@end

@interface GSMutableArray : NSMutableArray
{
@public
	id       *_contents_array;
	unsigned  _count;
	unsigned  _capacity;
	int       _grow_factor;
}
@end

#define CASE(x) if(strcmp(aVariable, #x) == 0)
#define serializeUsing()\
{\
	CASE(_contents_array)\
	{\
		id back = [aSerializer backend];\
		/* Cheat and store the count in the wrong order */\
		[back storeUnsignedInt:_count withName:"_count"];\
		for(unsigned int i=0 ; i<_count ; i++)\
		{\
			char * saveName;\
			if (asprintf(&saveName, "_contents_array.%d", i) == -1)\
			{\
				[NSException raise: NSMallocException\
				            format: @"Not enough space to allocate buffer"];\
			}\
			id element = _contents_array[i];\
			[aSerializer storeObjectFromAddress: &element withName:saveName];\
			free(saveName);\
		}\
		return YES;\
	}\
	CASE(_count)\
	{\
		return YES;\
	}\
	return [super serialize:aVariable using:aSerializer];\
}
#define deserializeFromPointer()\
{\
	CASE(_count)\
	{\
		_contents_array = calloc(*(unsigned*)aBlob, sizeof(id));\
	}\
	int index;\
	if(sscanf(aVariable, "_contents_array.%d", &index) == 1)\
	{\
		NSAssert(_count, @"Can't deserialize data before array size in GSArray");\
		return &_contents_array[index];\
	}\
	return [super deserialize:aVariable fromPointer:aBlob version:aVersion];\
}
/**
 * Category for correctly serializing array objects.
 */
@implementation GSArray (ETSerializable)
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	serializeUsing();
}
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	deserializeFromPointer();
}
@end
@implementation GSMutableArray (ETSerializable)
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	serializeUsing();
}
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	deserializeFromPointer();
}
- (void) finishedDeserializing
{
	if(_capacity != _count)
	{
		_contents_array = realloc(_contents_array, _capacity * sizeof(id));
	}
}
@end
