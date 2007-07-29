#import "ETSerialiser.h"
#import "ETDeserialiser.h"

@interface	NSDataStatic : NSData
{
	unsigned	length;
	void		*bytes;
}
@end

@implementation NSDataStatic(ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend
{
	if([super serialise:aVariable using:aBackend])
	{
		return YES;
	}
	if(strcmp(aVariable, "bytes") == 0)
	{
		[aBackend storeData:bytes
					 ofSize:length
				   withName:"bytes"];
		return YES;
	}
	return NO;
}
@end
