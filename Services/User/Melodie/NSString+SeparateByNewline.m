#import <Foundation/Foundation.h>

#pragma GCC diagnostic ignored "-Wunreachable-code" /* For NSMakeRange macro issue */

@interface NSString (SeparateByNewline)
- (NSArray *) componentsSeparatedByNewline;
@end

@implementation NSString (SeparateByNewline)
- (NSArray *) componentsSeparatedByNewline
{
	NSMutableArray *array = [NSMutableArray array];
	NSUInteger length = [self length];
	NSUInteger lineStart = 0;
	NSUInteger lineEnd = 0;
	NSUInteger stringEnd = 0;
	while (lineEnd < length)
	{
		[self getLineStart: &lineStart
		               end: &lineEnd
		       contentsEnd: &stringEnd
		          forRange: NSMakeRange(lineEnd, 0)];
		[array addObject: [self substringWithRange:
			 NSMakeRange(lineStart, stringEnd - lineStart)]];
	}
	return array;
}
@end


