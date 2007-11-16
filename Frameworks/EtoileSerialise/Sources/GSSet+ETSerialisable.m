#import "ETSerialiser.h"
#import "ETDeserialiser.h"
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
 * Category for correctly serialising array objects.
 */
@implementation NSSet (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(ETSerialiser*)aSerialiser
{
	CASE(map)
	{
		id back = [aSerialiser backend];
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
			[back storeObjectReference:COREF_FROM_ID(key) withName:saveName];
			[aSerialiser enqueueObject:key];
			free(saveName);
			i++;
			node = GSIMapEnumeratorNextNode(&enumerator);
		}
		GSIMapEndEnumerator(&enumerator);
		return YES;
	}
	return [super serialise:aVariable using:aSerialiser];
}
- (void*) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	id** objects = (id**)&MAP_IVAR;
	CASE(_count)
	{
		unsigned count = *(unsigned*)aBlob;
		*objects = calloc(count + 1, sizeof(id));
		(*objects)[0] = (id)count;
	}
	int index;
	if(sscanf(aVariable, "map.%d", &index) == 1)
	{
		return &(*objects)[index];
	}
	return NULL;
}
- (void) finishedDeserialising
{
	id* objects = *(id**)&MAP_IVAR;
	[self initWithObjects:objects+1 count:(unsigned)(unsigned long)objects[0]];
	free(objects);
}
@end
