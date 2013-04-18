#import "EtoileText.h"

@implementation ETStyleBuilder
@synthesize style;
- (id)init
{
	SUPERINIT;
	styleTransformers = [NSMutableDictionary new];
	return self;
}
- (void)dealloc
{
	[styleTransformers release];
	[style release];
	[super dealloc];
}
- (void)registerTransformer: (ETStyleTransformer*)aTransformer
               forTypeNamed: (NSString*)styleName
{
	[styleTransformers setObject: aTransformer
	                      forKey: styleName];
}
/**
 * Merges in a presentation attribute.
 */
- (void)mergeStyleAttribute: (id)attribute forKey: (NSString*)aKey
{

}
- (void)addAttributesForType: (id)type
{
	NSString *name = [type valueForKey: kETTextStyleName];

	if (nil == name) { return; }

	id<ETStyleTransformer> transformer = [styleTransformers objectForKey: name];
	NSDictionary *attributes = [transformer presentationAttributesForType: type];

	if (nil != attributes)
	{
		[self addCustomAttributes: attributes];
	}

}
- (void)addAttributesForStyle: (id)style
{
	// TODO: Combine with -addAttributeForType:
}
- (void)addCustomAttributes: (NSDictionary*)attributes
{

}
@end
