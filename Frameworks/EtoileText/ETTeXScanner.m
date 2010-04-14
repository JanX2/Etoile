#import "EtoileText.h"

static NSCharacterSet *CommandEndCharacterSet;

#define BUFFER_SIZE 64
#define PASS_TEXT() \
	if (textRange.length > 0)\
	{\
		[delegate handleText: [aString substringWithRange: textRange]];\
		textRange.location = idx;\
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
		range.location += BUFFER_SIZE;
		for (unsigned i=0 ; i<range.length ; i++)
		{
			unichar c = buffer[i];
			idx++;
			switch (c)
			{
				case '{':
					PASS_TEXT();
					[delegate beginArgument];
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
							textRange.length++;
							PASS_TEXT();
						}
						else
						{
							PASS_TEXT();
							NSRange r = 
								[aString rangeOfCharacterFromSet: CommandEndCharacterSet
								                         options: 0
								                           range: NSMakeRange(idx, end - idx)];
							if (NSNotFound == r.location)
							{
								r.location = end - 1;
							}
							r.length = r.location - idx;
							r.location = idx;
							[delegate beginCommand: [aString substringWithRange: r]];
							i += r.location - idx;
							if (i > BUFFER_SIZE)
							{
								range.location += BUFFER_SIZE - i;
							}
							idx = r.location;
							textRange.location = idx;
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
