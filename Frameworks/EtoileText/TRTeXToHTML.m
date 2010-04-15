#import "EtoileText.h"
#import <EtoileFoundation/EtoileFoundation.h>

@interface ETTeXSimpleHandler : ETTeXParser
{
	BOOL isStarted;
}
@end
@implementation ETTeXSimpleHandler
- (void)beginCommand: (NSString*)aCommand
{
	if (!isStarted)
	{
		// TODO: Register mappings and use a dictionary.
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				aCommand, @"typeName")]];
		isStarted = YES;
	}
	else
	{
		// This is a command inside the main one.
		id root = self.parent;
		id parentParent = [root parent];
		while (nil != parentParent)
		{
			root = parentParent;
			parentParent = [root parent];
		}
		[root beginCommand: aCommand];
	}
}
- (void)endArgument
{
	[self.builder endNode];
	self.scanner.delegate = self.parent;
}
- (void)handleText: (NSString*)aString
{
	[self.builder appendString: aString];
}
@end
/**
 * Parser for the subset of LaTeX that I use.
 */
@interface ETTeXSectionHandler : ETTeXParser
@end
@implementation ETTeXSectionHandler
static NSDictionary *HeadingTypes;
+ (void)initialize
{
	if (nil == HeadingTypes)
	{
		HeadingTypes = [D(
				@"chapter", [NSNumber numberWithInt: 1],
				@"section", [NSNumber numberWithInt: 2],
				@"subsection", [NSNumber numberWithInt: 3],
				@"subsubsection", [NSNumber numberWithInt: 4],
				@"subsubsubsection", [NSNumber numberWithInt: 5],
				@"paragraph", [NSNumber numberWithInt: 6]
		) retain];
	}
}
- (void)beginCommand: (NSString*)aCommand
{
	[self.builder endNode];
	[self.builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			@"heading", @"typeName",
			[HeadingTypes objectForKey: aCommand], @"depth")]];
}
- (void)endArgument
{
	[self.builder endNode];
	[self.builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			@"paragraph", @"typeName")]];
	self.scanner.delegate = self.parent;
}
- (void)handleText: (NSString*)aString
{
	[self.builder appendString: aString];
}
@end

int main(void)
{
	[NSAutoreleasePool new];
	ETTeXScanner *s = [ETTeXScanner new];
	NSString * tex = [NSString stringWithContentsOfFile: @"/tmp/tex"];
	ETTeXParser *d2 = [ETTeXParser new];
	[d2 registerDelegate: [ETTeXSectionHandler class]
			  forCommand: @"chapter"];
	[d2 registerDelegate: [ETTeXSectionHandler class]
			  forCommand: @"section"];
	[d2 registerDelegate: [ETTeXSectionHandler class]
			  forCommand: @"subsection"];
	[d2 registerDelegate: [ETTeXSimpleHandler class]
			  forCommand: @"keyword"];
	[d2 registerDelegate: [ETTeXSimpleHandler class]
			  forCommand: @"class"];
	[d2 registerDelegate: [ETTeXSimpleHandler class]
			  forCommand: @"code"];
	[d2 registerDelegate: [ETTeXSimpleHandler class]
			  forCommand: @"index"];
	d2.scanner = s;
	s.delegate = d2;
	[s parseString: tex];
	NSLog(@"Parsed TeX: %@", d2.document.text);
}
