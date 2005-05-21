#ifndef __LUCENE_INDEX_INDEX_READER__
#define __LUCENE_INDEX_INDEX_READER__

#include <Foundation/Foundation.h>
#include <LuceneKit/Index/LCTermDocs.h>
#include <LuceneKit/Index/LCTermFreqVector.h>
#include <LuceneKit/Index/LCTermPositions.h>
#include <LuceneKit/Index/LCSegmentInfos.h>
#include <LuceneKit/Document/LCDocument.h>

typedef enum _LCFieldOption
{
	// all fields
	LCFieldOption_ALL = 0,
	// all indexed fields
	LCFieldOption_INDEXED,
	// all fields which are not indexed
	LCFieldOption_UNINDEXED,
	// all fields which are indexed with termvectors enables
	LCFieldOption_INDEXED_WITH_TERMVECTOR,
	// all fields which are indexed but don't have termvectors enabled
	LCFieldOption_INDEXED_NO_TERMVECTOR,
	// all fields where termvectors are enabled. Please note that only standard termvector fields are returned
	LCFieldOption_TERMVECTOR,
	// all field with termvectors wiht positions enabled
	LCFieldOption_TERMVECTOR_WITH_POSITION,
	// all fields where termvectors with offset position are set
	LCFieldOption_TERMVECTOR_WITH_OFFSET,
	// all fields where termvectors with offset and position values set
	LCFieldOption_TERMVECTOR_WITH_POSITION_OFFSET
} LCFieldOption;

@interface LCIndexReader: NSObject <NSCopying>
{
	id <LCDirectory> directory;
	BOOL directoryOwner;
	BOOL closeDirectory;
	
	LCSegmentInfos *segmentInfos;
	// Lock writeLock
	BOOL stale;
	BOOL hasChanges;
}

- (id) initWithDirectory: (id <LCDirectory>) directory;
- (id) initWithDirectory: (id <LCDirectory>) dir       
			segmentInfos: (LCSegmentInfos *) seg       
		  closeDirectory: (BOOL) close;
- (id) initWithDirectory: (id <LCDirectory>) dir       
			segmentInfos: (LCSegmentInfos *) seg       
		  closeDirectory: (BOOL) close
		  directoryOwner: (BOOL) owner;
+ (LCIndexReader *) openPath: (NSString *) path;
+ (LCIndexReader *) openDirectory: (id <LCDirectory>) directory;
- (id <LCDirectory>) directory;
+ (long) currentVersionAtPath: (NSString *) path;
+ (long) currentVersionWithDirectory: (id <LCDirectory>) dir;
- (NSArray *) termFreqVectors: (int) number;
- (id <LCTermFreqVector>) termFreqVector: (int) docNumber
								   field: (NSString *) field;
+ (BOOL) indexExistsAtPath: (NSString *) dir;
+ (BOOL) indexExistsWithDirectory: (id <LCDirectory>) dir;
- (int) numberOfDocuments;
- (int) maximalDocument;
- (LCDocument *) document: (int) n;
- (BOOL) isDeleted: (int) n;
- (BOOL) hasDeletions;
- (NSData *) norms: (NSString *) field;
- (void) setNorms: (NSString *) field 
            bytes: (NSMutableData *) bytes offset: (int) offset;
- (void) setNorm: (int) doc field: (NSString *) field charValue: (char) value;
- (void) doSetNorm: (int) doc field: (NSString *) field charValue: (char) value;
- (void) setNorm: (int) doc field: (NSString *) field floatValue: (float) value;
- (LCTermEnumerator *) terms;
- (LCTermEnumerator *) termsWithTerm: (LCTerm *) t;
- (long) documentFrequency: (LCTerm *) t;
- (id <LCTermDocs>) termDocsWithTerm: (LCTerm *) term;
- (id <LCTermDocs>) termDocs;
- (id <LCTermPositions>) termPositionsWithTerm: (LCTerm *) term;
- (id <LCTermPositions>) termPositions;
- (void) delete: (int) docNum;
- (void) doDelete: (int) docNum;
- (int) deleteTerm: (LCTerm *) term;
- (void) undeleteAll;
- (void) doUndeleteAll;
- (void) commit;
- (void) doCommit;
- (void) close;
- (void) doClose;
- (NSArray *) fieldNames: (LCFieldOption) fieldOption;
+ (BOOL) isLocked: (id <LCDirectory>) dir;
- (BOOL) isLockedAtPath: (NSString *) dir;
- (void) unlock: (id <LCDirectory>) dir;

@end

#endif /* __LUCENE_INDEX_INDEX_READER__ */
