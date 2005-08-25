#include <LuceneKit/Analysis/LCAnalyzer.h>
#include <LuceneKit/GNUstep/GNUstep.h>
#include <UnitKit/UnitKit.h>
#include <LuceneKit/Java/LCStringReader.h>

@interface LCAnalyzer (UKTest_Additions)
- (void) compare: (NSString *) s and: (NSArray *) a
            with: (LCAnalyzer *) analyzer;
@end

