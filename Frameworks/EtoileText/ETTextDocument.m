#import <EtoileFoundation/EtoileFoundation.h>
#import "EtoileText.h"

@implementation ETTextDocument
@synthesize text;
- (id)init
{
	SUPERINIT;
	types = [NSMutableSet new];
	return self;
}
- (void)dealloc
{
	[types release];
	[super dealloc];
}
- (id)typeFromDictionary: (NSDictionary*)aDictionary
{
	id type = [types member: aDictionary];
	if (nil == type)
	{
		[types addObject: aDictionary];
		type = aDictionary;
	}
	return type;
}
@end

