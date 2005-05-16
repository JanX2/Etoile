#include <LuceneKit/Analysis/LCCharTokenizer.h>
#include <LuceneKit/Java/LCReader.h>
#include <LuceneKit/GNUstep/GNUstep.h>

/** An abstract base class for simple, character-oriented tokenizers.*/
@implementation LCCharTokenizer

- (id) initWithReader: (id) r
{
	self = [super initWithReader: r];
	offset = 0;
	bufferIndex = 0;
	dataLen = 0;
	return self;
}

/** Returns true iff a character should be included in a token.  This
* tokenizer generates as tokens adjacent sequences of characters which
* satisfy this predicate.  Characters for which this is false are used to
* define token boundaries and are not included in tokens. */
- (BOOL) isTokenChar: (char) c
{
	return NO;
}

/** Called on each token character to normalize it before it is added to the
* token.  The default implementation does nothing.  Subclasses may use this
* to, e.g., lowercase tokens. */
- (char) normalize: (char) c
{
	return c;
}

- (LCToken *) next
{
	/** Returns the next token in the stream, or null at EOS. */
	int length = 0;
	int start = offset;
	unichar c;
	//  NSData *data;
	while (YES) 
    {
		offset++;
		if (bufferIndex >= dataLen) 
        {
			dataLen = [input read: ioBuffer length: IO_BUFFER_SIZE];
			bufferIndex = 0;
        }
		
		if (dataLen < 1 /* == -1 */) 
        {
			if (length > 0)
				break;
			else
				return nil;
        } 
		else
			c = ioBuffer[bufferIndex++];
		
		if ([self isTokenChar: c])                // if it's a token char
        {
			if (length == 0)			           // start of token
				start = offset - 1;
			
			buffer[length++] = [self normalize: c]; // buffer it, normalized
			
			if (length == MAX_WORD_LEN)		   // buffer overflow!
				break;
			
        } 
		else if (length > 0)             // at non-Letter w/ chars
			break;                           // return 'em
		
    }
	
	NSString *s = [NSString stringWithCharacters: buffer length: length];
	LCToken *t = [[LCToken alloc] initWithText: s start: start 
										   end: start + length];
	return AUTORELEASE(t);
}

@end
