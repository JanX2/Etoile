#ifndef __LUCENE_SEARCH_EXACT_PHRASE_SCORER__
#define __LUCENE_SEARCH_EXACT_PHRASE_SCORER__

#include "Search/LCPhraseScorer.h"

@interface LCExactPhraseScorer: LCPhraseScorer
- (id) initWithWeight: (LCWeight *) weight
       termPositions: (NSArray *) tps
       positions: (NSArray *) positions
       similarity: (LCSimilarity *) similarity
       norms: (NSData *) norms;
- (float) phraseFreq;
@end

#endif /* __LUCENE_SEARCH_EXACT_PHRASE_SCORER__ */
