#ifndef __LUCENE_SEARCH_SIMILARITY__
#define __LUCENE_SEARCH_SIMILARITY__

#include <Foundation/Foundation.h>

static float *NORM_TABLE;

//@class LCSearcher;
@class LCTerm;

@interface LCSimilarity: NSObject
{
}

+ (void) setDefaultSimilarity: (LCSimilarity *) similarity;
+ (LCSimilarity *) defaultSimilarity;
+ (float) decodeNorm: (char) b;
+ (float *) normDecoder;
- (float) lengthNorm: (NSString *) fieldName numberOfTokens: (int) numTokens;
- (float) queryNorm: (float) sumOfSquredWeights;
+ (char) encodeNorm: (float) f;
+ (float) byteToFloat: (char) b;
+ (char) floatToByte: (float) f;
- (float) tfWithInt: (int) freq;
- (float) sloppyFreq: (int) distance;
- (float) tfWithFloat: (float) freq;
#if 0
- (float) idf: (LCTerm *) term
          searcher: (LCSearcher *) searcher;
- (float) idfTerms: (NSArray *) terms
          searcher: (LCSearcher *) searcher;
#endif
- (float) idfDocFreq: (int) docFreq numDocs: (int) numDocs;
- (float) coord: (int) overlap max: (int) maxOverlap;

@end
#endif /* __LUCENE_SEARCH_SIMILARITY__ */
