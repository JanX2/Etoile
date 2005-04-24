#include "Search/LCSearcher.h"
#include "Search/LCSimilarity.h"
#include "Search/LCHits.h"
#include "Search/LCQuery.h"
#include "Search/LCSort.h"
#include "Search/LCFilter.h"
#include "Search/LCHitCollector.h"
#include "GNUstep/GNUstep.h"
#include "Search/LCWeight.h"

/** An abstract base class for search implementations.
 * Implements some common utility methods.
 */
@implementation LCSearcher

- (id) init
{
  self = [super init];
  ASSIGN(similarity, [LCSimilarity defaultSimilarity]);
  return self;
}

  /** Returns the documents matching <code>query</code>. 
   * @throws BooleanQuery.TooManyClauses
   */
- (LCHits *) search: (LCQuery *) query
{
  return [self search: query filter: nil];
}

  /** Returns the documents matching <code>query</code> and
   * <code>filter</code>.
   * @throws BooleanQuery.TooManyClauses
   */
- (LCHits *) search: (LCQuery *) query
              filter: (LCFilter *) filter
{
  return AUTORELEASE([[LCHits alloc] initWithSearcher: self query: query filter: filter]);
}

  /** Returns documents matching <code>query</code> sorted by
   * <code>sort</code>.
   * @throws BooleanQuery.TooManyClauses
   */
- (LCHits *) search: (LCQuery *) query sort: (LCSort *) sort
{
  return AUTORELEASE([[LCHits alloc] initWithSearcher: self query: query filter: nil sort: sort]);
}

  /** Returns documents matching <code>query</code> and <code>filter</code>,
   * sorted by <code>sort</code>.
   * @throws BooleanQuery.TooManyClauses
   */
- (LCHits *) search: (LCQuery *) query 
             filter: (LCFilter *) filter sort: (LCSort *) sort
{
  return AUTORELEASE([[LCHits alloc] initWithSearcher: self query: query filter: filter sort: sort]);
}

  /** Lower-level search API.
   *
   * <p>{@link HitCollector#collect(int,float)} is called for every non-zero
   * scoring document.
   *
   * <p>Applications should only use this if they need <i>all</i> of the
   * matching documents.  The high-level search API ({@link
   * Searcher#search(Query)}) is usually more efficient, as it skips
   * non-high-scoring hits.
   * <p>Note: The <code>score</code> passed to this method is a raw score.
   * In other words, the score will not necessarily be a float whose value is
   * between 0 and 1.
   * @throws BooleanQuery.TooManyClauses
   */
- (void) search: (LCQuery *) query
	   hitCollector: (LCHitCollector *) results
{
  /* FIXME: lucene use deprecated method */
#if 1
  [self search: [query weight: self] filter: nil hitCollector: results];
#else
  [self search: query filter: nil hitCollector: results];
#endif
}    

  /** Expert: Set the Similarity implementation used by this Searcher.
   *
   * @see Similarity#setDefault(Similarity)
   */
- (void) setSimilarity: (LCSimilarity *) s
{
  ASSIGN(similarity, s);
}

  /** Expert: Return the Similarity implementation used by this Searcher.
   *
   * <p>This defaults to the current value of {@link Similarity#getDefault()}.
   */
- (LCSimilarity *) similarity
{
  return similarity;
}

- (void) search: (id <LCWeight>) weight 
         filter: (LCFilter *) filter
	 hitCollector: (LCHitCollector *) results {}
- (void) close {}
- (int) documentFrequencyWithTerm: (LCTerm *) term { return -1; }
- (NSArray *) documentFrequencyWithTerms: (NSArray *) terms { return nil; }
- (int) maximalDocument { return -1; }
- (LCTopDocs *) search: (id <LCWeight>) weight 
                filter: (LCFilter *) filter
		maximum: (int) n
{ return nil; }
- (LCDocument *) document: (int) i { return nil; }
- (LCQuery *) rewrite: (LCQuery *) query { return nil; }
- (LCExplanation *) explainWithQuery: (LCQuery *) query
                      document: (int) doc
{ return nil; }
- (LCExplanation *) explainWithWeight: (id <LCWeight>) weight 
                      document: (int) doc
{ return nil; }
- (LCTopFieldDocs *) search: (id <LCWeight>) weight 
		     filter: (LCFilter *) filter
		     maximum: (int) n
		     sort: (LCSort *) sort
{  return nil; }
@end
