#import "EtoileText.h"

static NSCharacterSet *CommandEndCharacterSet;

#define BUFFER_SIZE 64
#define PASS_TEXT() \
	if (textRange.length > 0)\
	{\
		[delegate handleText: [aString substringWithRange: textRange]];\
		textRange.location = idx+1;\
		textRange.length = 0;\
	}

@implementation ETTeXScanner
@synthesize delegate;
+ (void)initialize
{
	if ([ETTeXScanner class] != self) { return; }
	CommandEndCharacterSet = 
		[[NSCharacterSet characterSetWithCharactersInString: @"\n\t\\ {["] retain];
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
					textRange.location++;
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
						// Special case for escaped slash
						if ([aString characterAtIndex: idx+1] == '\\')
						{
							//FIXME
							textRange.length++;
							PASS_TEXT();
						}
						else
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
							if (i+1 > range.length)
							{
								//NSLog(@"Out of buffer");
								range.location = idx + 1;
							}
							textRange.location = idx + 1;
							//NSLog(@"Continuing from %d (%d) %c %@", idx, i, [aString characterAtIndex: idx], NSStringFromRange(textRange));
						}
					}
					break;
				default:
					textRange.length++;
			}
		}
	}
	PASS_TEXT();
}
@end

@implementation ETTeXParser
@synthesize parent, document, builder, scanner;
- (id)init
{
	SUPERINIT;
	commandHandlers = [NSMutableDictionary new];
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
		}
		return;
	}
	id<ETTeXParsing> d = [[handler new] autorelease];
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
- root
{
	if (nil == root)
	{
		// Commands inside the environment
		root = self.parent;
		id parentParent = [root parent];
		while (nil != parentParent)
		{
			root = parentParent;
			parentParent = [root parent];
		}
	}
	return root;
}
@end
