#ifndef __LUCENE_ANALYSIS_ANALYZER__
#define __LUCENE_ANALYSIS_ANALYZER__

#include <Foundation/Foundation.h>
#include "Java/LCReader.h"
#include "LCTokenStream.h"

@interface LCAnalyzer: NSObject
{
}

- (LCTokenStream *) tokenStreamWithField: (NSString *) name
                                  reader: (id <LCReader>) reader;
@end

#ifdef HAVE_UKTEST
@interface LCAnalyzer (UKTest_Additions)
- (void) compare: (NSString *) s and: (NSArray *) a 
            with: (LCAnalyzer *) analyzer;
@end
#endif /* HAVE_UKTEST */

#endif /* __LUCENE_ANALYSIS_ANALYZER__ */
