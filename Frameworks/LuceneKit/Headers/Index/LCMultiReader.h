#ifndef __LUCENE_INDEX_MULTI_READER__
#define __LUCENE_INDEX_MULTI_READER__

#include <LuceneKit/Index/LCIndexReader.h>
#include <LuceneKit/Index/LCTermDocs.h>
#include <LuceneKit/Index/LCTermPositions.h>
#include <LuceneKit/Store/LCDirectory.h>

@class LCSegmentMergeQueue;

@interface LCMultiTermEnumerator: LCTermEnumerator
{
	LCSegmentMergeQueue *queue;
	LCTerm *term;
	long docFreq;
}
- (id) initWithReaders: (NSArray *) reader
				starts: (NSArray *) starts
				  term: (LCTerm *) t;
@end

@interface LCMultiTermDocs: NSObject <LCTermDocs>
{
	NSArray *readers;
	NSArray *starts; // 1st docno for each segment
	LCTerm *term;
	int base;
	int pointer;
	NSMutableArray *readerTermDocs;
	id <LCTermDocs> current;
}
- (id) initWithReaders: (NSArray *) r 
                starts: (NSArray *) s;
- (id <LCTermDocs>) termDocsWithReader: (LCIndexReader *) reader;
@end

@interface LCMultiTermPositions: LCMultiTermDocs <LCTermPositions>
@end

@interface LCMultiReader: LCIndexReader
{
	NSArray *subReaders; // array of LCIndexReader
	NSMutableArray *starts;  // array of int, 1st docno for each segment
	NSMutableDictionary *normsCache;
	int maxDoc;
	int numDocs;
	BOOL hasDeletions;
}

- (id) initWithReaders: (NSArray *) subReaders;
- (id) initWithDirectory: (id <LCDirectory>) directory
			segmentInfos: (LCSegmentInfos *) sis
				   close: (BOOL) closeDirectory
				 readers: (NSArray *) subReaders;
@end

#endif /* __LUCENE_INDEX_MULTI_READER__ */
