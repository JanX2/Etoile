#import "EtoileText.h"

static NSCharacterSet *CommandEndCharacterSet;

#define BUFFER_SIZE 64
#define PASS_TEXT() \
	if (textRange.length > 0)\
	{\
		[delegate handleText: [aString substringWithRange: textRange]];\
		textRange.length = 0;\
	}\
	textRange.location = idx+1;

@implementation ETTeXScanner
@synthesize delegate;
+ (void)initialize
{
	if ([ETTeXScanner class] != self) { return; }
	CommandEndCharacterSet = 
		[[NSCharacterSet characterSetWithCharactersInString: @"\n\t\\ {[]}"] retain];
}
- (void)parseString: (NSString*)aString
{
	NSUInteger end = [aString length];

	NSRange range = { 0, BUFFER_SIZE };
	NSRange textRange = { 0, 0 };
	NSUInteger idx = 0;
	while (range.location < end)
	{
		unichar buffer[BUFFER_SIZE];
		if (range.location + range.length > end)
		{
			range.length = end - range.location;
		}
		[aString getCharacters: buffer range: range];
		//NSLog(@"Buffer: %@", [aString substringWithRange: range]);
		range.location += BUFFER_SIZE;
		for (unsigned i=0 ; i<range.length ; i++, idx++)
		{
			unichar c = buffer[i];
			switch (c)
			{
				case '{':
					PASS_TEXT();
					[delegate beginArgument];
					//NSLog(@"Text range: %@", NSStringFromRange(textRange));
					break;
				case '}':
					PASS_TEXT();
					[delegate endArgument];
					break;
				case '[':
					PASS_TEXT();
					[delegate beginOptArg];
					break;
				case ']':
					PASS_TEXT();
					[delegate endOptArg];
					break;
				case '\\':
					if (idx != end)
					{
						// Special case for escaped control characters
						switch ([aString characterAtIndex: idx+1])
						{
							case '\\':
							case '_':
							case '%':
							{
								PASS_TEXT();
								// Skip the slash:
								i++;
								idx++;
								// We've already parsed the next character, so
								// add it to the text range.
								textRange.length = 1;
								break;
							}
							default:
							{
								PASS_TEXT();
								NSUInteger start = idx + 1;
								// Find the end of the command
								NSRange r = 
									[aString rangeOfCharacterFromSet: CommandEndCharacterSet
															 options: 0
															   range: NSMakeRange(start, end-start)];
								// Command goes to the end of the input.
								if (NSNotFound == r.location)
								{
									r.location = end - 1;
								}
								r.length = r.location - start;
								r.location = start;
								[delegate beginCommand: [aString substringWithRange: r]];
								idx += r.length;
								i += r.length;
								textRange.location = idx + 1;
								//NSLog(@"Continuing from %d (%d) %c %@", idx, i, [aString characterAtIndex: idx], NSStringFromRange(textRange));
							}
						}
						if (i+1 > range.length)
						{
							//NSLog(@"Out of buffer");
							range.location = idx + 1;
						}
					}
					break;
				case '-':
				{
					if (idx + 1 < end)
					{
						if ([aString characterAtIndex: idx+1] == '-')
						{
							PASS_TEXT();
							unichar dash = 8211; // en
							int skip = 1;
							if (idx + 2 < end)
							{
								if ([aString characterAtIndex: idx+1] == '-')
								{
									skip = 2;
									dash = 8212; // em
								}
							}
							NSString *dashString = [NSString stringWithCharacters: &dash length: 1];
							[delegate handleText: dashString];
							idx += skip;
							i += skip;
							if (i+1 > range.length)
							{
								range.location = idx + 1;
							}
							textRange.location = idx + 1;
							break;
						}
					}
					textRange.length++;
					break;
				}
				case '\'':
				{
					PASS_TEXT();
					unichar quote = 8217; // '
					if (idx + 1 < end)
					{
						if ([aString characterAtIndex: idx+1] == '\'')
						{
							quote = 8221; // ''
							idx += 1;
							i += 1;
							if (i+1 > range.length)
							{
								range.location = idx + 1;
							}
						}
					}
					NSString *quoteString = [NSString stringWithCharacters: &quote length: 1];
					[delegate handleText: quoteString];
					textRange.location = idx + 1;
					break;
				}
				case '`':
				{
					PASS_TEXT();
					unichar quote = 8216; // `
					if (idx + 1 < end)
					{
						if ([aString characterAtIndex: idx+1] == '`')
						{
							quote = 8220; // `
							idx += 1;
							i += 1;
							if (i+1 > range.length)
							{
								range.location = idx + 1;
							}
						}
					}
					NSString *quoteString = [NSString stringWithCharacters: &quote length: 1];
					[delegate handleText: quoteString];
					textRange.location = idx + 1;
					break;
				}
				default:
					textRange.length++;
			}
		}
	}
	PASS_TEXT();
}
@end

@implementation ETTeXParser
@synthesize parent, document, builder, scanner, root;
static NSDictionary *DefaultCommandHandlers;
+ (void)initialize
{
	if ([ETTeXParser class] != self) { return; }

	// Some standard command handlers.
	DefaultCommandHandlers = [D(
		[ETTeXSectionHandler class], @"part*",
		[ETTeXSectionHandler class], @"chapter*",
		[ETTeXSectionHandler class], @"section*",
		[ETTeXSectionHandler class], @"subsection*",
		[ETTeXSectionHandler class], @"subsubsection*",
		[ETTeXSectionHandler class], @"paragraph*",
		[ETTeXSectionHandler class], @"part",
		[ETTeXSectionHandler class], @"chapter",
		[ETTeXSectionHandler class], @"section",
		[ETTeXSectionHandler class], @"subsection",
		[ETTeXSectionHandler class], @"subsubsection",
		[ETTeXSectionHandler class], @"paragraph",
		[ETTeXNestableHandler class], @"ks",
		[ETTeXNestableHandler class], @"file",
		[ETTeXNestableHandler class], @"java",
		[ETTeXNonNestedHandler class], @"cxx",
		[ETTeXNonNestedHandler class], @"code",
		[ETTeXNestableHandler class], @"note",
		[ETTeXNestableHandler class], @"textit",
		[ETTeXNestableHandler class], @"footnote",
		[ETTeXLabelHandler class], @"label",
		[ETTeXRefHandler class], @"ref",
		[ETTeXRefHandler class], @"pageref",
		[ETTeXEnvironmentHandler class], @"begin",
		[ETTeXItemHandler class], @"item",
		[ETTeXIndexHandler class], @"index") retain];
}
- (id)init
{
	SUPERINIT;
	commandHandlers = [DefaultCommandHandlers mutableCopy];
	unknownTags = [NSMutableSet new];
	builder = [ETTextTreeBuilder new];
	document = [ETTextDocument new];
	document.text = builder.textTree;
	paragraphType = 
		[document typeFromDictionary: D(
			ETTextParagraphType, kETTextStyleName)];
	return self;
}
- (void)dealloc
{
	[commandHandlers release];
	[unknownTags release];
	[builder release];
	[scanner release];
	[super dealloc];
}
- (void)registerDelegate: (Class)aClass forCommand: (NSString*)command
{
	NSAssert([aClass conformsToProtocol: @protocol(ETTeXParsing)],
			@"Handlers must conform to the ETTeXParsing protocol");
	[commandHandlers setObject: aClass forKey: command];
}
- (void)beginCommand: (NSString*)aCommand
{
	Class handler = [commandHandlers objectForKey: aCommand];
	if (nil == handler)
	{
		if (![unknownTags containsObject: aCommand])
		{
			[unknownTags addObject: aCommand];
			NSLog(@"No handler registered for: %@", aCommand);
			NSLog(@"Currently using %@", scanner.delegate);
		}
		return;
	}
	id<ETTeXParsing> d = [[handler new] autorelease];
	d.root = self;
	d.scanner = scanner;
	// Note: Not self, so that children can call this
	d.parent = (id<ETTeXParsing>)scanner.delegate;
	d.builder = builder;
	d.document = document;
	scanner.delegate = d;
	[d beginCommand: aCommand];
}
- (void)beginOptArg {}
- (void)endOptArg {}
- (void)beginArgument {}
- (void)endArgument {}
- (void)handleText: (NSString*)aString
{
	NSArray *paragraphs = [aString componentsSeparatedByString: @"\n\n"];

	NSString *p0 = [paragraphs objectAtIndex: 0];

	// If this segment starts with a blank line, end the existing paragraph and
	// start a new one.
	if ([@"" isEqualToString: p0])
	{
		[self beginParagraph];
	}
	else
	{
		[self addTextToParagraph: p0];
	}
	NSInteger c = [paragraphs count];
	NSInteger i = 1;
	while (i<c - 1)
	{
		NSString *p = [paragraphs objectAtIndex: i];
		[self beginParagraph];
		[self addTextToParagraph: p];
		i++;
	}
	if (c-1 > 0)
	{
		p0 = [paragraphs objectAtIndex: c-1];
		if ([@"" isEqualToString: p0])
		{
			[self beginParagraph];
		}
		else
		{
			[self beginParagraph];
			[self addTextToParagraph: p0];
		}
	}

}
- (void)beginParagraph
{
	if (isInParagraph)
	{
		[builder endNode];
	}
	[builder startNodeWithStyle: paragraphType];
	isInParagraph = YES;
}
- (void)endParagraph
{
	if (isInParagraph)
	{
		[builder endNode];
		isInParagraph = NO;
	}
}
- (void)addTextToParagraph: (NSString*)aString
{
	if (!isInParagraph)
	{
		[self beginParagraph];
	}
	[builder appendString: aString];
}
@end

@implementation ETTeXHandler
@synthesize parent, document, builder, scanner, root;
- (void)beginCommand: (NSString*)aCommand
{
	[root beginCommand: aCommand];
}
- (void)beginOptArg
{
	[self.builder appendString: @"["];
}
- (void)endOptArg
{
	[self.builder appendString: @"]"];
}
- (void)beginArgument {}
- (void)endArgument {}
- (void)handleText: (NSString*)aString
{
	[root handleText: aString];
}
@end

