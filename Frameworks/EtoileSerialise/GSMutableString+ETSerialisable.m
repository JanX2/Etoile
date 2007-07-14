#import "GSPrivate.h"
#import "ETSerialiser.h"
#import "ETDeserialiser.h"

@implementation GSMutableString (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend
{
	if(strcmp(aVariable, "_flags") == 0)
	{
		[aBackend storeInt:*(int*)&_flags withName:"_flags"];
		return YES;
	}
	else if(strcmp(aVariable, "_contents") == 0)
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
	return NO;
}
- (BOOL) deserialise:(char*)aVariable fromPointer:(void*)aBlob
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
