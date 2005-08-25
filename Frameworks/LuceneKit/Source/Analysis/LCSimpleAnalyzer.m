#include <LuceneKit/Analysis/LCSimpleAnalyzer.h>
#include <LuceneKit/Analysis/LCLowerCaseTokenizer.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@implementation LCSimpleAnalyzer

/** An Analyzer that filters LetterTokenizer with LowerCaseFilter. */
- (LCTokenStream *) tokenStreamWithField: (NSString *) name
								  reader: (id <LCReader>) reader
{
	LCLowerCaseTokenizer *tokenizer = [[LCLowerCaseTokenizer alloc] initWithReader: reader];
	return AUTORELEASE(tokenizer); 
}

@end
