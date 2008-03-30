#import "ETSerializer.h"
#import "ETDeserializer.h"

@interface	NSDataStatic : NSData
{
	unsigned	length;
	void		*bytes;
}
@end

/**
 * Category on NSDataStatic to correctly store the data.
 */
@implementation NSDataStatic(ETSerializable)
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	if([super serialize:aVariable using:aSerializer])
	{
		return YES;
	}
	if(strcmp(aVariable, "bytes") == 0)
	{
		[[aSerializer backend] storeData:bytes
								  ofSize:length
								withName:"bytes"];
		return YES;
	}
	return NO;
}
@end
