#import "EtoileText.h"
#import <EtoileFoundation/EtoileFoundation.h>

@interface ETTeXSimpleHandler : ETTeXParser
{
	BOOL isStarted;
}
+ (void)setTextType: (NSString*) aType forTeXCommand: (NSString*) aCommand;
@end
@implementation ETTeXSimpleHandler
static NSMutableDictionary *CommandTypes;
+ (void)initialize
{
	if ([ETTeXSimpleHandler class] != self) { return; }
	CommandTypes = [NSMutableDictionary new];
}
+ (void)setTextType: (NSString*) aType forTeXCommand: (NSString*) aCommand
{
	[CommandTypes setObject: aCommand forKey: aType];
}
- (void)beginCommand: (NSString*)aCommand
{
	if (!isStarted)
	{
		NSString *type = [CommandTypes objectForKey: aCommand];
		if (nil == type)
		{
			type = aCommand;
		}
		// TODO: Register mappings and use a dictionary.
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				type, kETTextStyleName)]];
		isStarted = YES;
	}
	else
	{
		// This is a command inside the main one.
		[[self root] beginCommand: aCommand];
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
	[[self root] beginCommand: aCommand];
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
	[[self root] handleText: aString];
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
				[NSNumber numberWithInt: 0], @"part",
				[NSNumber numberWithInt: 1], @"chapter",
				[NSNumber numberWithInt: 2], @"section",
				[NSNumber numberWithInt: 3], @"subsection",
				[NSNumber numberWithInt: 4], @"subsubsection",
				[NSNumber numberWithInt: 5], @"subsubsubsection",
				[NSNumber numberWithInt: 6], @"paragraph"
		) retain];
	}
}
- (void)beginCommand: (NSString*)aCommand
{
	[[self root] endParagraph];
	[self.builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextHeadingType, kETTextStyleName,
			[HeadingTypes objectForKey: aCommand], kETTextHeadingLevel)]];
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

@interface ETTeXIndexHandler : ETTeXLinkHandler @end
@implementation ETTeXIndexHandler
- (void)beginCommand: (NSString*)aCommand
{
	NSAssert([@"index" isEqualToString: aCommand],
			@"\\index{} does not support internal commands (patches welcome!)");
}
- (void)handleText: (NSString*)aString
{
	attributes = [D(
			ETTextLinkTargetType, kETTextStyleName,
			aString, kETTextLinkIndexText,
			[ETUUID UUID], kETTextLinkName) retain];
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
		[[self root] endParagraph];
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

@interface TRTeXClassHandler : ETTeXParser
@end
@implementation TRTeXClassHandler
- (void)handleText: (NSString*)aString
{
	ETTextTreeBuilder *builder = self.builder;
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			@"code", kETTextStyleName)]];
	[builder appendString: aString];
	[builder endNode];
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextLinkTargetType, kETTextStyleName,
			([NSString stringWithFormat: @"%@ class", aString]), kETTextLinkIndexText,
			[ETUUID UUID], kETTextLinkName)]];
	[self.builder endNode];
}
- (void)endArgument
{
	self.scanner.delegate = self.parent;
}
@end

@interface TRXHTMLWriter : NSObject <ETTextVisitor>
{
	ETXMLWriter *writer;
}
- (NSString*)endDocument;
@end
@implementation TRXHTMLWriter
- (id)init
{
	SUPERINIT;
	writer = [ETXMLWriter new];
	//[writer setAutoindent: YES];
	[writer startElement: @"html"]; 
	[writer startElement: @"head"]; 
	{
		[writer startAndEndElement: @"link"
		                attributes: D(@"stylesheet", @"rel",
		                              @"text/css", @"type",
		                              @"tex.css", @"href")];
	}
	[writer endElement];
	[writer startElement: @"body"]; 
	return self;
}
- (void)startTextNode: (id<ETText>)aNode
{
	NSString *typeName = [aNode.textType valueForKey: kETTextStyleName];
	if (nil != typeName)
	{
		//TODO: Handle standard attributes here, call a delegate for others.
		NSDictionary *attributes = nil;
		if ([ETTextParagraphType isEqualToString: typeName])
		{
			typeName = @"p";
		}
		else if ([ETTextHeadingType isEqualToString: typeName])
		{
			typeName = [NSString stringWithFormat: @"h%@",
					[aNode.textType valueForKey: kETTextHeadingLevel]];
		}
		else if ([@"textit" isEqualToString: typeName])
		{
			typeName = @"i";
		}
		else if ([@"code" isEqualToString: typeName])
		{
			attributes = D(@"code", @"class");
			typeName = @"span";
		}
		else if ([@"notebox" isEqualToString: typeName])
		{
			attributes = D(@"notebox", @"class");
			typeName = @"div";
		}
		else if ([@"keyword" isEqualToString: typeName])
		{
			attributes = D(@"keyword", @"class");
			typeName = @"span";
		}
		else if ([ETTextForeignImportType isEqualToString: typeName])
		{
			// TODO: Differenc class for each snippet type
			[writer startElement: @"pre"];
			// FIXME: don't hard-code path!  Very bad!
			NSString *file = [NSString stringWithContentsOfFile: 
					[NSString stringWithFormat: @"/tmp/startsnippets/%@", 
						[aNode.textType valueForKey: kETTextSourceLocation]]];
			NSArray *lines = [file componentsSeparatedByString: @"\n"];
			NSInteger start = [[aNode.textType valueForKey: kETTextFirstLine] integerValue];
			NSInteger end = [[aNode.textType valueForKey: kETTextLastLine] integerValue];
			// If start is specified, then make it to 0-indexed 
			if (start > 0) { start -= 1; }
			if (end == 0) { end = [lines count] - 1; }
			for (NSInteger i=start ; i<end ; i++)
			{
				NSString *line = [lines objectAtIndex: i];
				[writer characters: line];
				[writer characters: @"\n"];
			}
			[writer endElement];
			[writer startElement: @"p"
					  attributes: D(@"caption", @"class")];
			[writer characters: @"From: "];
			[writer characters: [aNode.textType valueForKey: kETTextSourceLocation]];
			return;
		}
		else
		{
			//typeName = @"span";
		}
		[writer startElement: typeName
				  attributes: attributes];
	}
}
- (void)visitTextNode: (id<ETText>)aNode
{
	NSString *str = [[aNode stringValue] stringByTrimmingCharactersInSet:
		[NSCharacterSet newlineCharacterSet]];
	if ([str length] > 0)
	{
		[writer characters: str];
	}
}
- (void)endTextNode: (id<ETText>)aNode
{
	if (nil != [aNode.textType valueForKey: kETTextStyleName])
	{
		[writer endElement];
	}
}
- (NSString*)endDocument
{
	[writer endElement];
	[writer endElement];
	return [writer endDocument];
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
	// FIXME: Should emit Index ref as well.
	[d2 registerDelegate: [ETTeXSimpleHandler class]
			  forCommand: @"keyword"];
	[d2 registerDelegate: [TRTeXClassHandler class]
			  forCommand: @"class"];
	[d2 registerDelegate: [ETTeXSimpleHandler class]
			  forCommand: @"code"];
	[d2 registerDelegate: [ETTeXSimpleHandler class]
			  forCommand: @"textit"];
	[d2 registerDelegate: [ETTeXSimpleHandler class]
			  forCommand: @"footnote"];
	[d2 registerDelegate: [ETTeXLabelHandler class]
			  forCommand: @"label"];
	[d2 registerDelegate: [ETTeXRefHandler class]
			  forCommand: @"ref"];
	[d2 registerDelegate: [ETTeXRefHandler class]
			  forCommand: @"pageref"];
	[d2 registerDelegate: [ETTeXEnvironmentHandler class]
			  forCommand: @"begin"];
	[d2 registerDelegate: [ETTeXIndexHandler class]
			  forCommand: @"index"];
	[d2 registerDelegate: [TRTeXImportedListing class]
			  forCommand: @"function"];
	[d2 registerDelegate: [TRTeXImportedListing class]
			  forCommand: @"startsnippet"];
	[d2 registerDelegate: [TRTeXImportedListing class]
			  forCommand: @"startsnippetindent"];
	d2.scanner = s;
	s.delegate = d2;
	[s parseString: tex];
	TRXHTMLWriter *w = [TRXHTMLWriter new];
	NSLog(@"Parsed TeX: \n%@", d2.document.text);
	[d2.document.text visitWithVisitor: w];
	NSString *html = [w endDocument];
	NSLog(@"Parsed TeX: \n%@", html);
	[html writeToFile: @"tex.html" atomically: NO];
}
