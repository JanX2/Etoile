#ifndef __LUCENE_SEARCH_WEIGHT__
#define __LUCENE_SEARCH_WEIGHT__

#include <Foundation/Foundation.h>

@protocol LCWeight <NSObject> //Serializable
- (LCQuery *) query;
- (float) value;
- (float) sumOfSquredWeights;
- (void) normalize: (float) norm;
- (LCScorer *) scorer: (LCIndexReader *) reader;
- (LCExplanation *) explain: (LCindexReader *) reader
                      doc: (int) doc;
@end
#endif /* __LUCENE_SEARCH_WEIGHT__ */
