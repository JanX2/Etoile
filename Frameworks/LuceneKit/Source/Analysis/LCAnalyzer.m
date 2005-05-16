#include <LuceneKit/Analysis/LCAnalyzer.h>
#include <LuceneKit/Java/LCReader.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@implementation LCAnalyzer
/** An Analyzer builds TokenStreams, which analyze text.  It thus represents a
*  policy for extracting index terms from text.
*  <p>
*  Typical implementations first build a Tokenizer, which breaks the stream of
*  characters from the Reader into raw Tokens.  One or more TokenFilters may
*  then be applied to the output of the Tokenizer.
*  <p>
*  WARNING: You must override one of the methods defined by this class in your
*  subclass or the Analyzer will enter an infinite loop.
*/

/** Creates a TokenStream which tokenizes all the text in the provided
Reader.  Default implementation forwards to tokenStream(Reader) for 
compatibility with older version.  Override to allow Analyzer to choose 
strategy based on document and/or field.  Must be able to handle null
field name for backward compatibility. */
- (LCTokenStream *) tokenStreamWithField: (NSString *) name
								  reader: (id <LCReader>) reader
{
	return nil;
}

@end

#ifdef HAVE_UKTEST

#include <UnitKit/UnitKit.h>
#include <LuceneKit/Java/LCStringReader.h>

@implementation LCAnalyzer (UKTest_Additions)
- (void) compare: (NSString *) s and: (NSArray *) a 
            with: (LCAnalyzer *) analyzer
{
	LCStringReader *reader = [[LCStringReader alloc] initWithString: s];
	LCTokenStream *stream = [analyzer tokenStreamWithField: @"contents"
													reader: reader];
	int i = 0;
	LCToken *token;
	while((token = [stream next]))
    {
		UKStringsEqual([a objectAtIndex: i++], [token termText]);
    }
	
	RELEASE(reader);
}
@end

#endif
