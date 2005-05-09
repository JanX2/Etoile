#ifndef __LUCENE_INDEX_DOCUMENT_WRITER__
#define __LUCENE_INDEX_DOCUMENT_WRITER__

#include <Foundation/Foundation.h>
#include "Store/LCDirectory.h"
#include "Analysis/LCAnalyzer.h"
#include "Search/LCSimilarity.h"
#include "Document/LCDocument.h"
#include "Index/LCIndexWriter.h"

@class LCTermVectorOffsetInfo;
@class LCTerm;
@class LCFieldInfos;

@interface LCDocumentWriter: NSObject
{
	LCAnalyzer *analyzer;
	id <LCDirectory> directory;
	LCSimilarity *similarity;
	LCFieldInfos *fieldInfos;
	int maxFieldLength;
	int termIndexInterval;
	
	// Keys are Terms, values are Postings.
	// Used to buffer a document before it is written to the index.
	NSMutableDictionary *postingTable;
	NSMutableArray *fieldsCache;
	NSMutableArray *fieldBoosts; // flost
	
	LCTerm *termBuffer;
}

- (id) initWithDirectory: (id <LCDirectory>) directory
				analyzer: (LCAnalyzer *) analyzer
			  similarity: (LCSimilarity *) similarity
		  maxFieldLength: (int) maxFieldLength;
- (id) initWithDirectory: (id <LCDirectory>) directory
				analyzer: (LCAnalyzer *) analyzer
			 indexWriter: (LCIndexWriter *) indexWriter;
- (void) addDocument: (NSString *) segment
			document: (LCDocument *) doc;

@end

#endif /* __LUCENE_INDEX_DOCUMENT_WRITER__ */
