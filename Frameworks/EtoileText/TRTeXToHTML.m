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
				aCommand, kETTextStyleName)]];
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

@interface ETTeXEnvironmentHandler : ETTeXParser
{
	NSString *environmentName;
	BOOL inBegin;
	BOOL inEnd;
}
@end

@implementation ETTeXEnvironmentHandler
- (void)beginCommand: (NSString*)aCommand
{
	if (nil == environmentName)
	{
		NSAssert([@"begin" isEqualToString: aCommand],
				@"Environment must stat with \\begin!");
		return;
	}
	if ([@"end" isEqualToString: aCommand])
	{
		inEnd = YES;
		return;
	}
	// Commands inside the environment
	id root = self.parent;
	id parentParent = [root parent];
	while (nil != parentParent)
	{
		root = parentParent;
		parentParent = [root parent];
	}
	[root beginCommand: aCommand];
}
- (void)beginArgument
{
	if (nil == environmentName)
	{
		inBegin = YES;
	}
}
- (void)endArgument
{
	if (inEnd)
	{
		[self.builder endNode];
		self.scanner.delegate = self.parent;
	}
}
- (void)handleText: (NSString*)aString
{
	if (inBegin)
	{
		ASSIGN(environmentName, aString);
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				aString, kETTextStyleName)]];
		inBegin = NO;
		return;
	}
	if (inEnd)
	{
		NSAssert([aString isEqualToString: environmentName],
				@"\\end does not match \\begin!");
		return;
	}
	NSArray *paragraphs = [aString componentsSeparatedByString: @"\n\n"];
	for (NSString *p in paragraphs)
	{
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				ETTextParagraphType, kETTextStyleName)]];
		[self.builder appendString: p];
		[self.builder endNode];
	}
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
				@"part", [NSNumber numberWithInt: 0],
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
			ETTextHeadingType, kETTextStyleName,
			[HeadingTypes objectForKey: aCommand], kETTextHeadingLevel)]];
}
- (void)endArgument
{
	[self.builder endNode];
	[self.builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextParagraphType, kETTextStyleName)]];
	self.scanner.delegate = self.parent;
}
- (void)handleText: (NSString*)aString
{
	[self.builder appendString: aString];
}
@end

@interface ETTeXLinkHandler : ETTeXParser
{
	NSMutableDictionary *attributes;
}
@end

@implementation ETTeXLinkHandler
- (void)dealloc
{
	[attributes release];
	[super dealloc];
}
- (void)endArgument
{
	[self.builder startNodeWithStyle: 
		[self.document typeFromDictionary: attributes]];
	[self.builder endNode];
	self.scanner.delegate = self.parent;
}
- (void)handleText: (NSString*)aString
{
	[attributes setObject: aString forKey: kETTextLinkName];
}
@end

@interface ETTeXRefHandler : ETTeXLinkHandler @end
@implementation ETTeXRefHandler
- (void)beginCommand: (NSString*)aCommand
{
	ASSIGN(attributes, 
		([NSMutableDictionary dictionaryWithObjectsAndKeys: 
			ETTextLinkType, kETTextStyleName,
			aCommand, @"LaTeXLinkType", nil]));
}
@end
@interface ETTeXLabelHandler : ETTeXLinkHandler @end
@implementation ETTeXLabelHandler
- (void)beginCommand: (NSString*)aCommand
{
	ASSIGN(attributes, 
		[NSMutableDictionary dictionaryWithObject: ETTextLinkTargetType
		                                   forKey: kETTextStyleName]);
}
@end

@interface TRTeXImportedListing : ETTeXParser
{
	NSString *refType;
	NSString *filename;
	NSNumber *firstLine;
	NSNumber *lastLine;
}
@end

@implementation TRTeXImportedListing
- (void)beginCommand: (NSString*)aCommand
{
	ASSIGN(refType, aCommand);
}
- (void)dealloc
{
	[refType release];
	[filename release];
	[firstLine release];
	[lastLine release];
	[super dealloc];
}
- (void)handleText: (NSString*)aString
{
	if (nil == filename)
	{
		ASSIGN(filename, aString);
	}
	else if (nil == firstLine)
	{
		ASSIGN(firstLine, [NSNumber numberWithInt: [aString intValue]]);
	}
	else if (nil == lastLine)
	{
		ASSIGN(lastLine, [NSNumber numberWithInt: [aString intValue]]);
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				ETTextForeignImportType, kETTextStyleName,
				filename, kETTextSourceLocation,
				firstLine, kETTextFirstLine,
				lastLine, kETTextLastLine,
				refType, @"TRImportType")]];
		[self.builder endNode];
		self.scanner.delegate = self.parent;
	}
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
			  forCommand: @"textit"];
	[d2 registerDelegate: [ETTeXLabelHandler class]
			  forCommand: @"label"];
	[d2 registerDelegate: [ETTeXRefHandler class]
			  forCommand: @"ref"];
	[d2 registerDelegate: [ETTeXRefHandler class]
			  forCommand: @"pageref"];
	[d2 registerDelegate: [ETTeXEnvironmentHandler class]
			  forCommand: @"begin"];
	[d2 registerDelegate: [TRTeXImportedListing class]
			  forCommand: @"function"];
	[d2 registerDelegate: [TRTeXImportedListing class]
			  forCommand: @"startsnippet"];
	[d2 registerDelegate: [TRTeXImportedListing class]
			  forCommand: @"startsnippetindent"];
	d2.scanner = s;
	s.delegate = d2;
	[s parseString: tex];
	NSLog(@"Parsed TeX: %@", d2.document.text);
}
