#import <Foundation/Foundation.h>

/* Delete this once NSRange works in Smalltalk */

@interface NSArray (NSRangeWorkaround)

- (NSArray *) subarrayWithLocation: (unsigned int) location length: (unsigned int) length;

@end

@implementation NSArray (NSRangeWorkaround)

- (NSArray *) subarrayWithLocation: (unsigned int) location length: (unsigned int) length
{
	NSRange range;
	range.location = location;
	range.length = length;
	return [self subarrayWithRange: range];
}

@end
