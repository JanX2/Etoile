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
*/

/** <override-subclass /> Creates a TokenStream which tokenizes all the text in the provided
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

