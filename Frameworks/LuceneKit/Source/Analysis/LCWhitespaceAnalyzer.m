#include "Analysis/LCWhitespaceAnalyzer.h"
#include "Analysis/LCWhitespaceTokenizer.h"
#include "GNUstep/GNUstep.h"

@implementation LCWhitespaceAnalyzer

- (LCTokenStream *) tokenStreamWithField: (NSString *) name
                                reader: (id <LCReader>) reader
{
  return AUTORELEASE([[LCWhitespaceTokenizer alloc] initWithReader: reader]);
}

#ifdef HAVE_UKTEST
- (void) testWhitespaceAnalyzer
{
  NSString *s = @"This is a beautiful day!";
  NSArray *a = [s componentsSeparatedByString: @" "];
//  LCWhitespaceAnalyzer *analyzer = [[LCWhitespaceAnalyzer alloc] init];
  [self compare: s and: a with: self /* analyzer */];
//  RELEASE(analyzer);
}
#endif

@end
