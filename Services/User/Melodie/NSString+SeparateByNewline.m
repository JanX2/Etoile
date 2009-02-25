#import <Foundation/Foundation.h>

@interface NSString (SeparateByNewline)
- (NSArray *) componentsSeparatedByNewline;
@end

@implementation NSString (SeparateByNewline)
- (NSArray *) componentsSeparatedByNewline
{
	NSMutableArray *array = [NSMutableArray array];
	unsigned int length = [self length];
	unsigned int lineStart = 0;
	unsigned int lineEnd = 0;
	unsigned int stringEnd = 0;
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


