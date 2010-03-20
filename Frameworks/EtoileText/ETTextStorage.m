#import <EtoileFoundation/EtoileFoundation.h>
#import "EtoileText.h"


@implementation ETTextStorage
@synthesize text,style;
- (NSString*)string
{
	return [text stringValue];
}
- (NSDictionary*)attributesAtIndex: (NSUInteger)anIndex
                    effectiveRange: (NSRangePointer)range
{
	// FIXME: This collects the style for intermediate nodes redundantly.  We
	// should probably have a caching mechanism, or this will perform very
	// badly on deep trees.
	NSUInteger end = [text buildStyleFromIndex: anIndex
	                          withStyleBuilder: style];
	if (NULL != range)
	{
		range->location = anIndex;
		range->length = end - anIndex;
	}
	return [style style];
}
- (void)replaceCharactersInRange: (NSRange)aRange
                      withString: (NSString*)aString
{
	[text replaceCharactersInRange: aRange
	                    withString: aString];
}
- (void)setAttributes: (NSDictionary*)attributes 
                range: (NSRange)aRange
{
	[text setCustomAttributes: attributes
	                    range: aRange];
}
@end
