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
}
@end

@implementation ETTeXParser
@synthesize parent, text, scanner;
- (id)init
{
	SUPERINIT;
	commandHandlers = [NSMutableDictionary new];
	text = [ETTextTree new];
	return self;
}
- (void)dealloc
{
	[commandHandlers release];
	[text release];
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
		NSLog(@"No handler registered for: %@", aCommand);
		return;
	}
	id d = [[handler new] autorelease];
	scanner.delegate = d;
	[d beginCommand: aCommand];
}
- (void)beginOptArg {}
- (void)endOptArg {}
- (void)beginArgument {}
- (void)endArgument {}
- (void)handleText: (NSString*)aString
{
	[text replaceCharactersInRange: NSMakeRange([text length], 0)
	                    withString: aString];
}
@end
