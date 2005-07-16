#ifndef __LUCENE_ANALYSIS_TOKEN_STREAM__
#define __LUCENE_ANALYSIS_TOKEN_STREAM__

#include <Foundation/Foundation.h>
#include <LuceneKit/Analysis/LCToken.h>

/** A stream of tokens */
@interface LCTokenStream: NSObject
{
}

/** Next token */
- (LCToken *) nextToken;
/** Close stream */
- (void) close;

@end

#endif /* __LUCENE_ANALYSIS_TOKEN_STREAM__ */
