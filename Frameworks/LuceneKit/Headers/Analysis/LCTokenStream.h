#ifndef __LUCENE_ANALYSIS_TOKEN_STREAM__
#define __LUCENE_ANALYSIS_TOKEN_STREAM__

#include <Foundation/Foundation.h>
#include <LuceneKit/Analysis/LCToken.h>

@interface LCTokenStream: NSObject
{
}

- (LCToken *) next;
- (void) close;

@end

#endif /* __LUCENE_ANALYSIS_TOKEN_STREAM__ */
