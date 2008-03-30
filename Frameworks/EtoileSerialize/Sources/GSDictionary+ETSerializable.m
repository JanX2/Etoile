#import "ETSerializer.h"
#import "ETDeserializer.h"
#import <GNUstepBase/GSIMap.h>
@interface GSDictionary : NSDictionary
{
	@public
		  GSIMapTable_t map;
}
@end
@class GSMutableDictionary;


#define MAP_IVAR (((GSDictionary*)self)->map)

#define CASE(x) if(strcmp(aVariable, #x) == 0)
/**
 * Category for correctly serializing array objects.
 */
@implementation NSDictionary (ETSerializable)
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
			//TODO: Work out why this is needed:
			id value = [self objectForKey:node->key.obj];//node->value.obj;
			asprintf(&saveName, "map.%d", i);
			[back storeObjectReference:COREF_FROM_ID(key) withName:saveName];
			[aSerializer enqueueObject:key];
			free(saveName);
			i++;
			asprintf(&saveName, "map.%d", i);
			[back storeObjectReference:COREF_FROM_ID(value) withName:saveName];
			[aSerializer enqueueObject:value];
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
		*objects = calloc(count * 2 + 2, sizeof(id));
		(*objects)[0] = (id)count;
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
	[self init];
	Class real = self->isa;
	self->isa = [GSMutableDictionary class];
	for(unsigned i=1 ; (objects)[i] != nil ; i+=2)
	{
		[(GSMutableDictionary*)self setObject:objects[i+1] forKey:objects[i]];
	}
	self->isa = real;
	free(objects);
}
@end
