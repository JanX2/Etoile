#import "GSPrivate.h"
#import "ETSerialiser.h"
#import "ETDeserialiser.h"

@implementation GSMutableString (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend
{
	if([super serialise:aVariable using:aBackend])
	{
		return YES;
	}
	if(strcmp(aVariable, "_flags") == 0)
	{
		[aBackend storeInt:*(int*)&_flags withName:"_flags"];
		return YES;
	}
	if(strcmp(aVariable, "_contents") == 0)
	{
		if(_flags.wide)
		{
			[aBackend storeData:_contents.u
						 ofSize:sizeof(unichar) * (_count + 1)
					   withName:"_contents"];
		}
		else
		{
			[aBackend storeData:_contents.c
						 ofSize:sizeof(char) * (_count + 1)
					   withName:"_contents"];
		}
		return YES;
	}
	/*
	if(strcmp(aVariable, "_zone") == 0)
	{
		//TODO: Make this serialise the zone properly
		[aBackend storeChar:'Z' withName:"_zone"];
		return YES;
	}*/
	return NO;
}
- (BOOL) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
{
	if(strcmp(aVariable, "_flags") == 0)
	{
		*(int*)&_flags = *(int*)aBlob;
		return YES;
	}
	/*
	if(strcmp(aVariable, "_zone") == 0)
	{
		_zone = NSDefaultMallocZone();
		return YES;
	}
	*/
	/* No deserialisation required for _contents; 
	 * blobs are automatically restored as-is */
	return NO;
}
@end
