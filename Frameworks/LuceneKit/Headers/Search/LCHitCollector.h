#ifndef __LUCENE_SEARCH_HIT_COLLECTOR__
#define __LUCENE_SEARCH_HIT_COLLECTOR__

#include <Foundation/Foundation.h>

@interface LCHitCollector: NSObject
- (void) collect: (int) doc score: (float) score;
@end

#endif /* __LUCENE_SEARCH_HIT_COLLECTOR__ */
