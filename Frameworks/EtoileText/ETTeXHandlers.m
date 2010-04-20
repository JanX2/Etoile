#import "EtoileText.h"

@implementation ETTeXSimpleHandler
static NSMutableDictionary *CommandTypes;
+ (void)initialize
{
	if ([ETTeXSimpleHandler class] != self) { return; }
	CommandTypes = [NSMutableDictionary new];
}
+ (void)setTextType: (NSString*)aType forTeXCommand: (NSString*)aCommand
{
	[CommandTypes setObject: aType forKey: aCommand];
}
- (void)beginCommand: (NSString*)aCommand
{
	if (!isStarted)
	{
		NSString *type = [CommandTypes objectForKey: aCommand];
		type = (type != nil) ? type : aCommand;
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				type, kETTextStyleName)]];
		isStarted = YES;
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
@implementation ETTeXNonNestedHandler
- (void)beginCommand: (NSString*)aCommand
{
	if (!isStarted)
	{
		[super beginCommand: aCommand];
	}
	else
	{
		[self.builder appendString: @"\\"];
		[self.builder appendString: aCommand];
		//NSLog(@"Found interior command: %@", aCommand);
	}
}
- (void)beginOptArg
{
	[self.builder appendString: @"["];
}
- (void)endOptArg
{
	[self.builder appendString: @"]"];
}
- (void)beginArgument
{
	if (depth > 0)
	{
		[self.builder appendString: @"{"];
	}
	depth++;
}
- (void)endArgument
{
	depth--;
	if (depth > 0)
	{
		[self.builder appendString: @"}"];
	}
	else
	{
		[super endArgument];
	}
}
- (void)handleText: (NSString*)aString
{
	[self.builder appendString: aString];
}
@end


@implementation ETTeXNestableHandler
- (void)beginCommand: (NSString*)aCommand
{
	if (!isStarted)
	{
		[super beginCommand: aCommand];
	}
	else
	{
		[root beginCommand: aCommand];
	}
}
@end


@implementation ETTeXEnvironmentHandler
static NSMutableDictionary *EnvironmentTypes;
static NSMutableSet *VerbatimEnvironments;
+ (void)initialize
{
	if ([ETTeXEnvironmentHandler class] != self) { return; }
	EnvironmentTypes = [D(
		ETTextListType, @"itemize",
		ETTextNumberedListType, @"enumerate",
		ETTextDescriptionListType, @"description") mutableCopy];
	VerbatimEnvironments = [NSMutableSet new];
}
+ (void)setTextType: (NSString*)aType forTeXEnvironment: (NSString*)aCommand
{
	[EnvironmentTypes setObject: aType forKey: aCommand];
}
+ (void)addVerbatimEnvironment: (NSString*)anEnvironment
{
	[VerbatimEnvironments addObject: anEnvironment];
}
- (void)beginCommand: (NSString*)aCommand
{
	if (nil == environmentName)
	{
		NSAssert([@"begin" isEqualToString: aCommand],
				@"Environment must start with \\begin!");
		[root endParagraph];
		return;
	}
	if ([@"end" isEqualToString: aCommand])
	{
		inEnd = YES;
		return;
	}
	if (isVerbatim)
	{
		[self.builder appendString: @"\\"];
		[self.builder appendString: aCommand];
	}
	else
	{
		[root beginCommand: aCommand];
	}
}
- (void)beginArgument
{
	if (nil == environmentName)
	{
		inBegin = YES;
	}
	else if (!inEnd && isVerbatim)
	{
		[self.builder appendString: @"{"];
	}
}
- (void)endArgument
{
	if (inEnd)
	{
		self.scanner.delegate = self.parent;
	}
	else if (inBegin)
	{
		inBegin = NO;
	}
	else if (!inBegin && isVerbatim)
	{
		[self.builder appendString: @"}"];
	}
}
- (void)handleText: (NSString*)aString
{
	if (inBegin)
	{
		ASSIGN(environmentName, aString);

		NSString *type = [EnvironmentTypes objectForKey: aString];
		type = (type != nil) ? type : aString;

		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				type, kETTextStyleName)]];
		isVerbatim = [VerbatimEnvironments containsObject: type];
		return;
	}
	if (inEnd)
	{
		NSAssert([aString isEqualToString: environmentName],
				@"\\end does not match \\begin!");
		[root endParagraph];
		[self.builder endNode];
		return;
	}
	[root handleText: aString];
}
@end

/**
 * Parser for the subset of LaTeX that I use.
 */
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
	NSNumber *depth = [HeadingTypes objectForKey: aCommand];
	if (nil != depth)
	{
		[root endParagraph];
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				ETTextHeadingType, kETTextStyleName,
				depth, kETTextHeadingLevel)]];
	}
	else
	{
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


@implementation ETTeXRefHandler
- (void)beginCommand: (NSString*)aCommand
{
	ASSIGN(attributes, 
		([NSMutableDictionary dictionaryWithObjectsAndKeys: 
			ETTextLinkType, kETTextStyleName,
			aCommand, @"LaTeXLinkType", nil]));
}
@end
@implementation ETTeXLabelHandler
- (void)beginCommand: (NSString*)aCommand
{
	ASSIGN(attributes, 
		[NSMutableDictionary dictionaryWithObject: ETTextLinkTargetType
		                                   forKey: kETTextStyleName]);
}
@end

@implementation ETTeXItemHandler
- (void)beginCommand: (NSString*)aCommand
{
	if ([@"item" isEqualToString: aCommand])
	{
		if (startedBody)
		{
			[self.builder endNode];
		}
		startedBody = inOptArg = hasOptArg = NO;
	}
	else if ([@"end" isEqualToString: aCommand])
	{
		if (startedBody)
		{
			[self.builder endNode];
		}
		self.scanner.delegate = self.parent;
		[self.parent beginCommand: aCommand];
	}
	else
	{
		[root beginCommand: aCommand];
	}
}
- (void)beginOptArg
{
	inOptArg = YES;
	hasOptArg = YES;
	[self.builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextListDescriptionTitleType, kETTextStyleName)]];
}
- (void)endOptArg
{
	inOptArg = NO;
	[self.builder endNode];
}
- (void)handleText: (NSString*)aString
{
	if (!startedBody && !inOptArg)
	{
		startedBody = YES;
		NSString *type = hasOptArg ? ETTextListDescriptionItemType :
			ETTextListItemType;
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				type, kETTextStyleName)]];
	}
	[self.builder appendString: aString];
}
@end
