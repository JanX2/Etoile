#ifndef __LUCENE_INDEX_TERM_ENUM__
#define __LUCENE_INDEX_TERM_ENUM__

#include <Foundation/Foundation.h>
#include <LuceneKit/Index/LCTerm.h>

@interface LCTermEnum: NSObject
{
}

- (BOOL) next;
- (LCTerm *) term;
- (long) documentFrequency;
- (void) close;
- (BOOL) skipTo: (LCTerm *) target;

@end

#endif /* __LUCENE_INDEX_TERM_ENUM__ */
