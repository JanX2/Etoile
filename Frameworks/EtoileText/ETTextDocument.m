#import <EtoileFoundation/EtoileFoundation.h>
#import "EtoileText.h"

@implementation ETTextDocument
@synthesize text;
- (id)init
{
	SUPERINIT;
	styleTransformers = [NSMutableDictionary new];
	return self;
}
- (void)registerTransformer: (ETStyleTransformer*)aTransformer
              forStyleNamed: (NSString*)styleName
{
	[styleTransformers setObject: aTransformer
	                      forKey: styleName];
}
- (id)styleFromDictionary: (NSDictionary*)aDictionary
{
	return [styles member: aDictionary];
}
@end

