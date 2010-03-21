#import <EtoileFoundation/EtoileFoundation.h>
#import "EtoileText.h"

@implementation ETTextDocument
@synthesize text;
- (id)init
{
	SUPERINIT;
	styleTransformers = [NSMutableDictionary new];
	types = [NSMutableSet new];
	return self;
}
- (void)dealloc
{
	[types release];
	[styleTransformers release];
	[super dealloc];
}
- (void)registerTransformer: (ETStyleTransformer*)aTransformer
              forStyleNamed: (NSString*)styleName
{
	[styleTransformers setObject: aTransformer
	                      forKey: styleName];
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

