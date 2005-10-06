#ifndef __LUCENE_ANALYSIS_ANALYZER__
#define __LUCENE_ANALYSIS_ANALYZER__

#include <Foundation/Foundation.h>
#include "LCReader.h"
#include "LCTokenStream.h"

@interface LCAnalyzer: NSObject
{
}

/* Return a stream of token */
- (LCTokenStream *) tokenStreamWithField: (NSString *) name
                                  reader: (id <LCReader>) reader;
@end

#endif /* __LUCENE_ANALYSIS_ANALYZER__ */
