#include <LuceneKit/Analysis/LCWhitespaceAnalyzer.h>
#include <LuceneKit/Analysis/LCWhitespaceTokenizer.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@implementation LCWhitespaceAnalyzer

- (LCTokenStream *) tokenStreamWithField: (NSString *) name
								  reader: (id <LCReader>) reader
{
	return AUTORELEASE([[LCWhitespaceTokenizer alloc] initWithReader: reader]);
}

@end
