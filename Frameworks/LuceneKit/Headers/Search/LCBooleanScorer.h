#ifndef __LUCENE_SEARCHER_BOOLEAN_SCORER__
#define __LUCENE_SEARCHER_BOOLEAN_SCORER__

#include "Searcher/LCScorer.h"

@interface SubScorer: NSObject
{
  LCScorer *scorer;
  BOOL isDone;
  BOOL required;
  BOOL prohibited;
  LCHitCollector *collector;
  LCSubScorer *next;
}

- (id) initWithScorer: (LCScorer *) scorer
       required: (BOOL) required
       prohibited: (BOOL) prohibited
       hitCollector: (LCHitCollector *) collector
       next: (LCSubScorer *) next;
@end

@interface LCBucket: NSObject
{
   int doc = -1; // tells if bucket is valid
   float score;  // incremental score
   int bits;     // used for bool constraints
   int coord;    // count of terms in score
   LCBucket *next;  // next valid bucket
}

/** A simple hash table of document scores within a range. */
@interface LCBucketTable: NSObject
{
  int SIZE;
  int MASK;

  NSArray *buckets;
  LCBucket *first;

  LCBooleanScorer *scorer;
}

- (id) initWithBooleanScorer: (LCBooleanScorer *) scorer;
- (int) size;
- (LCHitCollector *) newCollector: (int) mask;
@end

@interface LCCollector: LCHitCollector
{
  LCBucketTable *bucketTable;
  int mask;
}

- (id) initWithMask: (int) mask bucketTable: (LCBucketTable *) bucketTable;
- (void) collect: (int) doc score: (float) score;
@end

@interface BooleanScorer: LCScorer
{
  LCSubScorer *scorers;
  LCBucketTable *bucketTable;
  int maxCoord;
  NSArray *coordFactors;
  int requiredMask;
  int prohibitedMask;
  int nextMask;

  int end;
  LCBucket *current;
}

- (id) initWithSimilarity: (LCSimilarity *) similarity;
- (void) addScorer: (LCScorer *) scorer
         required: (BOOL) required
	 prohibited: (BOOL) prohibited;
- (void) computeCorrdFactors;
- (void) score: (LCHitCollector *) hc;
- (BOOL) score: (LCHitCollector *) hc
         max: (int) max;
- (int) doc;
- (BOOL) next;
- (float) score;

- (BOOL) skipTo: (int) target;
- (LCExplanation *) explain: (int) doc;

@end

#endif /* __LUCENE_SEARCHER_BOOLEAN_SCORER__ */
