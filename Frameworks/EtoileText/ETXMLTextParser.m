#import "EtoileText/EtoileText.h"

@implementation ETXMLTextParser
@synthesize document;
- (void)startElement: (NSString *)aName
          attributes: (NSDictionary*)attributes;
{
	if (depth > 0)
	{
		ETXMLTextParser *childParser =
			[[isa alloc] initWithXMLParser: parser
			                        parent: self
			                           key: @"Text"];
		childParser.document = document;
		[childParser startElement: aName
		               attributes: attributes];
		return;
	}
	[super startElement: aName attributes: attributes];
	NSMutableDictionary *dict = [attributes mutableCopy];
	if (nil == dict)
	{
		dict = [NSMutableDictionary new];
	}
	[dict setObject: aName
	         forKey: @"typeName"];
	style = [document typeFromDictionary: dict];
	value = [ETTextFragment new];
	[(ETTextFragment*)value setType: style];
	[dict release];
	// TODO: Custom style by parsing CSS from style attribute - take code from
	// ETXML
}
- (void)characters: (NSString *)aString
{
	if ([value isKindOfClass: [ETTextFragment class]])
	{
		[value replaceCharactersInRange: NSMakeRange([value length], 0)
		                     withString: aString];
	}
	else
	{
		ETTextFragment *fragment = 
			[[ETTextFragment alloc] initWithString: aString];
		[value appendTextFragment: fragment];
		[fragment release];
	}
}
- (void)addText: (id<ETText>)aChild
{
	if ([value isKindOfClass: [ETTextFragment class]])
	{
		ETTextFragment *fragment = value;
		ETTextTree *tree = [ETTextTree textTreeWithChildren: A(value, aChild)];
		tree.customAttributes = fragment.customAttributes;
		fragment.customAttributes = nil;
		tree.type = fragment.type;
		fragment.type = nil;
		value = tree;
	}
	else
	{
		[value appendTextFragment: aChild];
	}
}
@end
