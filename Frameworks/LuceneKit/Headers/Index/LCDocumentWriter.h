#ifndef __LUCENE_INDEX_DOCUMENT_WRITER__
#define __LUCENE_INDEX_DOCUMENT_WRITER__

#include <Foundation/Foundation.h>
#include "Store/LCDirectory.h"

@class LCTermVectorOffsetInfo;
@class LCTerm;

@interface LCPosting: NSObject // info about a Term in a doc
{
	LCTerm *term; // the Term
	long freq; // its frequency in doc
	NSMutableArray *positions; //int // positions it occurs at
	NSMutableArray *offsets; // LCTermVectorOffsetInfo
}

- (id) initWithTerm: (LCTerm *) t
       position: (long) position
       offset: (LCTermVectorOffsetInfo *) offset;
- (LCTerm *) term;
- (long) freq;
- (NSMutableArray *) positions;
- (NSMutableArray *) offsets;
- (void) setFreq: (long) f;
- (void) setPositions: (NSArray *) p;
- (void) setOffsets: (NSArray *) o;
@end

@class LCSimilarity;
@class LCFieldInfos;
@class LCDocument;
@class LCAnalyzer;
@class LCIndexWriter;

@interface LCDocumentWriter: NSObject
{
	LCAnalyzer *analyzer;
	id <LCDirectory> directory;
	LCSimilarity *similarity;
	LCFieldInfos *fieldInfos;
	int maxFieldLength;
	int termIndexInterval;
	// PrintStream infoStream;
	
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
- (void) invertDocument: (LCDocument *) doc;
- (void) addField: (NSString *) field
             text: (NSString *) text
         position: (long) position
	 offset: (LCTermVectorOffsetInfo *) offset;
- (NSArray *) sortPostingTable;
#if 0
- (void) quickSort: (NSMutableArray *) postings
	 low: (int) lo high: (int) hi;
#endif
- (void) writePostings: (NSArray *) postings 
         segment: (NSString *) segment;
- (void) writeNorms: (NSString *) segment;
#if 0
- (void) setInfoStream: (PrintStream infoStream);
#endif
	
@end

#endif /* __LUCENE_INDEX_DOCUMENT_WRITER__ */
