#import "ETSerializer.h"
#import "ETSerializerBackend.h"
#import "ETDeserializer.h"
#import <GNUstepBase/GSIMap.h>
@interface GSSet : NSSet
{
	@public
		  GSIMapTable_t map;
}
@end

#define MAP_IVAR (((GSSet*)self)->map)

#define CASE(x) if(strcmp(aVariable, #x) == 0)
/**
 * Category for correctly serializing array objects.
 */
@implementation NSSet (ETSerializable)
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	CASE(map)
	{
		id back = [aSerializer backend];
		/* Cheat and store the count in the wrong order */
		[back storeUnsignedInt:MAP_IVAR.nodeCount withName:"_count"];
		GSIMapEnumerator_t enumerator = GSIMapEnumeratorForMap(&MAP_IVAR);
		GSIMapNode node = GSIMapEnumeratorNextNode(&enumerator);
		int i = 1;
		while (node != 0)
		{
			char * saveName;
			id key = node->key.obj;
			asprintf(&saveName, "map.%d", i);
			[aSerializer storeObjectFromAddress:&key withName:saveName];
			free(saveName);
			i++;
			node = GSIMapEnumeratorNextNode(&enumerator);
		}
		GSIMapEndEnumerator(&enumerator);
		return YES;
	}
	return [super serialize:aVariable using:aSerializer];
}
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	id** objects = (id**)&MAP_IVAR;
	CASE(_count)
	{
		unsigned count = *(unsigned*)aBlob;
		*objects = calloc(count + 1, sizeof(id));
		(*objects)[0] = (id)(intptr_t)count;
	}
	int index;
	if(sscanf(aVariable, "map.%d", &index) == 1)
	{
		return &(*objects)[index];
	}
	return NULL;
}
- (void) finishedDeserializing
{
	id* objects = *(id**)&MAP_IVAR;
	[self initWithObjects:objects+1 count:(unsigned)(unsigned long)objects[0]];
	free(objects);
}
@end
