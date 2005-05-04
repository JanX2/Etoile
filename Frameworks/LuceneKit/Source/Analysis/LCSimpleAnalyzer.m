#include "Analysis/LCSimpleAnalyzer.h"
#include "Analysis/LCLowerCaseTokenizer.h"
#include "GNUstep/GNUstep.h"

@implementation LCSimpleAnalyzer

/** An Analyzer that filters LetterTokenizer with LowerCaseFilter. */
- (LCTokenStream *) tokenStreamWithField: (NSString *) name
                                reader: (id <LCReader>) reader
{
  LCLowerCaseTokenizer *tokenizer = [[LCLowerCaseTokenizer alloc] initWithReader: reader];
 return AUTORELEASE(tokenizer); 
}

#ifdef HAVE_UKTEST
- (void) testSimpleAnalyzer
{
  NSString *s = @"This is a beautiful day!";
  NSArray *a = [NSArray arrayWithObjects: @"this", @"is", @"a", @"beautiful", @"day", nil];
  [self compare: s and: a with: self];
}
#endif /* HAVE_UKTEST */

@end
