#import "GSPrivate.h"
#import "ETSerialiser.h"
#import "ETDeserialiser.h"

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
	if(strcmp(aVariable, "_flags") == 0)
	{
		[[aSerialiser backend] storeInt:*(int*)&_flags withName:"_flags"];
		return YES;
	}
	if(strcmp(aVariable, "_contents") == 0)
	{
		if(_flags.wide)
		{
			[[aSerialiser backend] storeData:_contents.u
						 ofSize:sizeof(unichar) * (_count + 1)
					   withName:"_contents"];
		}
		else
		{
			[[aSerialiser backend] storeData:_contents.c
						 ofSize:sizeof(char) * (_count + 1)
					   withName:"_contents"];
		}
		return YES;
	}
	return [super serialise:aVariable using:aSerialiser];
}
/**
 * Load the flags and correctly.
 */
- (BOOL) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
{
	if(strcmp(aVariable, "_flags") == 0)
	{
		*(int*)&_flags = *(int*)aBlob;
		return YES;
	}
	/* No deserialisation required for _contents; 
	 * blobs are automatically restored as-is */
	return NO;
}
@end
