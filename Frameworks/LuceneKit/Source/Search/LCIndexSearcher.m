#include "Search/LCIndexSearcher.h"
#include "Search/LCFieldSortedHitQueue.h"
#include "Search/LCHitQueue.h"
#include "Search/LCFilter.h"
#include "Search/LCScoreDoc.h"
#include "Search/LCTopFieldDocs.h"
#include "Search/LCQuery.h"
#include "Search/LCSort.h"
#include "Util/LCBitVector.h"
#include "Index/LCIndexReader.h"
#include "Index/LCTerm.h"
#include "Document/LCDocument.h"
#include "GNUstep/GNUstep.h"

/** Implements search over a single IndexReader.
 *
 * <p>Applications usually need only call the inherited {@link #search(Query)}
 * or {@link #search(Query,Filter)} methods. For performance reasons it is 
 * recommended to open only one IndexSearcher and use it for all of your searches.
 */
@interface LCHitCollector1: LCHitCollector
{
  LCBitVector *bits;
  LCHitQueue *hq;
  int totalHits;
  float minScore;
  int nDocs;
}
- (id) initWithReader: (LCIndexReader *) reader
       filter: (LCFilter *) filter maximum: (int) nDos
       queue: (LCHitQueue *) hq;
- (int) totalHits;
@end

@implementation LCHitCollector1

- (id) initWithReader: (LCIndexReader *) reader
       filter: (LCFilter *) filter maximum: (int) n
       queue: (LCHitQueue *) q
{
  self = [self init];
  bits = (filter != nil) ? [filter bits: reader] : nil;
  nDocs = n;
  ASSIGN(hq, q);
  totalHits = 0;
  minScore = 0.0f;
  return self;
}

- (int) totalHits
{
  return totalHits;
}

- (void) collect: (int) doc score: (float) score
{
  if (score > 0.0f &&                     // ignore zeroed buckets
    ( bits == nil || [bits getBit: doc])) // skip docs not in bits
  {
    totalHits++;
    if ([hq size] < nDocs || score >= minScore) 
    {
      LCScoreDoc *d = [[LCScoreDoc alloc] initWithDocument: doc score: score];
      [hq insert: d];
      minScore = [((LCScoreDoc *)[hq top]) score]; // maintain minScore
    }
  }
}
@end

@interface LCHitCollector2: LCHitCollector
{
  LCBitVector *bits;
  LCFieldSortedHitQueue *hq;
  int totalHits;
  int nDocs;
}
- (id) initWithReader: (LCIndexReader *) reader
       filter: (LCFilter *) filter
       queue: (LCFieldSortedHitQueue *) hq;
- (int) totalHits;
@end

@implementation LCHitCollector2

- (id) initWithReader: (LCIndexReader *) reader
       filter: (LCFilter *) filter
       queue: (LCFieldSortedHitQueue *) q
{
  self = [self init];
  bits = (filter != nil) ? [filter bits: reader] : nil;
  ASSIGN(hq, q);
  totalHits = 0;
  return self;
}

- (int) totalHits
{
  return totalHits;
}

- (void) collect: (int) doc score: (float) score
{
  if (score > 0.0f &&                     // ignore zeroed buckets
    ( bits == nil || [bits getBit: doc])) // skip docs not in bits
  {
    totalHits++;
    LCFieldDoc *d = [[LCFieldDoc alloc] initWithDocument: doc score: score];
    [hq insert: d];
  }
}
@end

@interface LCHitCollector3: LCHitCollector
{
  LCBitVector *bits;
  LCHitCollector *collector;
}
- (id) initWithReader: (LCIndexReader *) reader
       filter: (LCFilter *) filter
       hitCollector: (LCHitCollector *) collector;
@end

@implementation LCHitCollector3

- (id) initWithReader: (LCIndexReader *) reader
       filter: (LCFilter *) filter
       hitCollector: (LCHitCollector *) hc 
{
  self = [self init];
  bits = [filter bits: reader];
  ASSIGN(collector, hc);
  return self;
}

- (void) collect: (int) doc score: (float) score
{
  if ([bits getBit: doc]) // skip docs not in bits
  {
    [collector collect: doc score: score];
  }
}
@end

@implementation LCIndexSearcher

  /** Creates a searcher searching the index in the named directory. */
- (id) initWithPath: (NSString *) path
{
  return [self initWithReader: [LCIndexReader openPath: path] close: YES];
}

  /** Creates a searcher searching the index in the provided directory. */
- (id) initWithDirectory: (id <LCDirectory>) directory
{
  return [self initWithReader: [LCIndexReader openDirectory: directory] 
	                close: YES];
}

  /** Creates a searcher searching the provided index. */
- (id) initWithReader: (LCIndexReader *) indexReader
{
  return [self initWithReader: indexReader close: NO];
}
  
- (id) initWithReader: (LCIndexReader *) indexReader close: (BOOL) close
{
  self = [self init];
  ASSIGN(reader, indexReader);
  closeReader = close;
  return self;
}

  /** Return the {@link IndexReader} this searches. */
- (LCIndexReader *) indexReader
{
  return reader;
}

  /**
   * Note that the underlying IndexReader is not closed, if
   * IndexSearcher was constructed with IndexSearcher(IndexReader r).
   * If the IndexReader was supplied implicitly by specifying a directory, then
   * the IndexReader gets closed.
   */
- (void) close
{
  if(closeReader)
    [reader close];
}

  // inherit javadoc
- (int) documentFrequencyWithTerm: (LCTerm *) term
{
  return [reader documentFrequency: term];
}

  // inherit javadoc
- (LCDocument *) document: (int) i
{
  return [reader document: i];
}

  // inherit javadoc
- (int) maximalDocument
{
  return [reader maximalDocument];
}

  // inherit javadoc
- (LCTopDocs *) search: (id <LCWeight>) weight
                filter: (LCFilter *) filter
		maximum: (int) nDocs
{
  if (nDocs <= 0)  // null might be returned from hq.top() below.
  {
    NSLog(@"nDocs must be > 0 ");
    return nil;
  }

  LCScorer *scorer = [weight scorer: reader];
  if (scorer == nil)
  {
    LCTopDocs *doc = [[LCTopDocs alloc] initWithTotalHits: 0
	                                scoreDocuments: [NSArray array]];
    return AUTORELEASE(doc);
  }

  LCHitQueue *hq = [[LCHitQueue alloc] initWithSize: nDocs];
  LCHitCollector1 *hc = [[LCHitCollector1 alloc] initWithReader: reader 
	                         filter: filter maximum: nDocs
				 queue: hq];
  [scorer score: hc];

  NSMutableArray *scoreDocs = [[NSMutableArray alloc] init];
  int i, count = [hq size];
  for (i = 0; i < count; i++) // put docs in array
  {
    [scoreDocs addObject: [hq pop]];
  }

  LCTopDocs *td = [[LCTopDocs alloc] initWithTotalHits: [hc totalHits]
	                             scoreDocuments: scoreDocs];
  return AUTORELEASE(td);
}

- (LCTopFieldDocs *) search: (id <LCWeight>) weight 
                     filter: (LCFilter *) filter
		     maximum: (int) nDocs
		     sort: (LCSort *) sort
{
  LCScorer *scorer = [weight scorer: reader];
  if (scorer == nil)
  {
    LCTopFieldDocs *doc = [[LCTopDocs alloc] initWithTotalHits: 0
	                                scoreDocuments: [NSArray array]
					sortFields: [sort sortFields]];
    return AUTORELEASE(doc);
  }

  LCFieldSortedHitQueue *hq = [[LCFieldSortedHitQueue alloc] initWithReader: reader sortFields: [sort sortFields] size: nDocs];
  LCHitCollector2 *hc = [[LCHitCollector2 alloc] initWithReader: reader 
	                         filter: filter queue: hq];
  [scorer score: hc];

  NSMutableArray *scoreDocs = [[NSMutableArray alloc] init];
  int i, count = [hq size];
  for (i = 0; i < count; i++) // put docs in array
  {
    LCFieldDoc *fieldDoc = [hq fillFields: [hq pop]];
   [scoreDocs addObject: fieldDoc];
  }

  LCTopFieldDocs *td = [[LCTopFieldDocs alloc] initWithTotalHits: [hc totalHits]
	                             scoreDocuments: scoreDocs
				     sortFields: [hq sortFields]];
  return AUTORELEASE(td);
}

- (void) search: (id <LCWeight>) weight 
         filter: (LCFilter *) filter
	 hitCollector: (LCHitCollector *) results
{
  LCHitCollector *collector = results;
  if (filter != nil) {
    collector = [[LCHitCollector3 alloc] initWithReader: reader 
	                         filter: filter hitCollector: results];
  }

  LCScorer *scorer = [weight scorer: reader];
  if (scorer == nil) return;
  [scorer score: collector];
}

- (LCQuery *) rewrite: (LCQuery *) original
{
  LCQuery *query = original;
  LCQuery *rewrittenQuery;
  for (rewrittenQuery = [query rewrite: reader]; rewrittenQuery != query;
         rewrittenQuery = [query rewrite: reader]) {
      query = rewrittenQuery;
  }
  return query;
}

- (LCExplanation *) explainWithQuery: (LCQuery *) query
                      document: (int) doc
{
  return [self explainWithWeight: [query weight: self]
	       document: doc];
}

- (LCExplanation *) explainWithWeight: (id <LCWeight>) weight 
                      document: (int) doc
{
  return [weight explain: reader document: doc];
}

@end
