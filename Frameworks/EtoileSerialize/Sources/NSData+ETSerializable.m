#import "ETSerializer.h"
#import "ETSerializerBackend.h"
#import "ETDeserializer.h"

/**
 * Category on NSData to correctly store the data.
 */
@implementation NSData (ETSerializable)
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	if([super serialize:aVariable using:aSerializer])
	{
		return YES;
	}
	// This is a horrible hack.  We really should use just the existing NSCoding stuff.
	if(strcmp(aVariable, "length") == 0)
	{
		id<ETSerializerBackend> back = [aSerializer backend];
		NSUInteger l = [self length];
		if (sizeof(NSUInteger) == sizeof(long long))
		{
			[back storeUnsignedLongLong: (unsigned long long)[self length]
			                   withName: "length"];
		}
		else
		{
			[back storeUnsignedInt: (unsigned int)[self length]
			              withName: "length"];
		}
		[[aSerializer backend] storeData: (void*)[self bytes]
								  ofSize: l
								withName: "bytes"];
		return YES;
	}
	if(strcmp(aVariable, "bytes") == 0) { return YES; }
	return NO;
}
@end
