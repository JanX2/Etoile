#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/CoreObject.h>
#import "EtoileText.h"

@implementation ETTextFragment
@synthesize parent, type, customAttributes;
- (id)initWithString: (NSString*)string
{
	SUPERINIT;
	text = [string mutableCopy];
	return self;
}
- (id)init
{
	return [self initWithString: @""];
}
- (NSString*)description
{
	NSString *typeName = [type objectForKey: @"typeName"];
	return [NSString stringWithFormat: @"<%@>%@</%@>", typeName, text, typeName];
}
- (void)setCustomAttributes: (NSDictionary*)attributes 
                      range: (NSRange)aRange {}
- (void)replaceCharactersInRange: (NSRange)range
                      withString: (NSString*)aString
{
	[text replaceCharactersInRange: range
	                    withString: aString];
	[parent childDidChange: self];
}
- (NSUInteger)buildStyleFromIndex: (NSUInteger)anIndex
                 withStyleBuilder: (ETStyleBuilder*)aBuilder
{
	[aBuilder addAttributesForStyle: type];
	if (nil != customAttributes)
	{
		[aBuilder addCustomAttributes: customAttributes];
	}
	return [text length];
}
- (NSUInteger)length
{
	return [text length];
}
- (unichar)characterAtIndex: (NSUInteger)anIndex
{
	return [text characterAtIndex: anIndex];
}
- (id<ETText>)splitAtIndex: (NSUInteger)anIndex
{
	NSString *str = [text substringToIndex: anIndex];
	ETTextFragment *first = [[ETTextFragment alloc] initWithString: str];
	first.customAttributes = customAttributes;
	first.type = type;
	NSRange r = NSMakeRange(0, anIndex);
	[text deleteCharactersInRange: r];
	return [first autorelease];
}
- (void)visitWithVisitor: (id<ETTextVisitor>)aVisitor
{
	[aVisitor startTextNode: self];
	[aVisitor visitTextNode: self];
	[aVisitor endTextNode: self];
}
- (NSString*)stringValue
{
	return text;
}
@end

