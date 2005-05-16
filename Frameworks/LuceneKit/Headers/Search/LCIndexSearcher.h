#ifndef __LUCENE_SEARCH_INDEX_SEARCHER__
#define __LUCENE_SEARCH_INDEX_SEARCHER__

#include <LuceneKit/Search/LCSearcher.h>
#include <LuceneKit/Store/LCDirectory.h>

@class LCIndexReader;
@class LCTerm;
@class LCDocument;

@interface LCIndexSearcher: LCSearcher
{
	LCIndexReader *reader;
	BOOL closeReader;
}

- (id) initWithPath: (NSString *) path;
- (id) initWithDirectory: (id <LCDirectory>) directory;
- (id) initWithReader: (LCIndexReader *) indexReader;
- (id) initWithReader: (LCIndexReader *) indexReader close: (BOOL) closeReader;
- (LCIndexReader *) indexReader;
@end

#endif /* __LUCENE_SEARCH_INDEX_SEARCHER__ */
