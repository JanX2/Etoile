#ifndef __LUCENE_SEARCH_HIT_COLLECTOR__
#define __LUCENE_SEARCH_HIT_COLLECTOR__

#include <Foundation/Foundation.h>

@interface LCHitCollector: NSObject
{
	id target;
	SEL selector;
}
- (void) collect: (int) doc score: (float) score;
- (void) setTarget: (id) target;
- (void) setSelector: (SEL) selector;
- (id) target;
- (SEL) selector;
@end

#endif /* __LUCENE_SEARCH_HIT_COLLECTOR__ */
