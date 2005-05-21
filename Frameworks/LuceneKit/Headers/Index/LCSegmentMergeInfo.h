#ifndef __LUCENE_INDEX_SEGMENT_MERGE_INFO__
#define __LUCENE_INDEX_SEGMENT_MERGE_INFO__

#include <Foundation/Foundation.h>
#include <LuceneKit/Index/LCTermPositions.h>
#include <LuceneKit/Util/LCPriorityQueue.h>
#include <LuceneKit/Index/LCIndexReader.h>

@interface LCSegmentMergeInfo: NSObject <LCComparable>
{
	LCTerm *term;
	int base;
	LCTermEnumerator *termEnum;
	LCIndexReader *reader;
	id <LCTermPositions> postings;
	NSMutableArray *docMap; // maps around deleted docs
}

- (id) initWithBase: (int) b termEnumerator: (LCTermEnumerator *) te 
			 reader: (LCIndexReader *) r;
- (LCTerm *) term;
- (LCTermEnumerator *) termEnumerator;
- (int) base;
- (BOOL) next;
- (void) close;
- (NSArray *) docMap;
- (id <LCTermPositions>) postings;
@end
#endif /* __LUCENE_INDEX_SEGMENT_MERGE_INFO__ */
