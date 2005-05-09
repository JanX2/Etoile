#ifndef __LUCENE_INDEX_SEGMENT_READER__
#define __LUCENE_INDEX_SEGMENT_READER__

#include "Index/LCIndexReader.h"
#include "Index/LCTermFreqVector.h"
#include "Index/LCFieldInfos.h"
#include "Index/LCCompoundFileReader.h"
#include "Index/LCSegmentInfo.h"
#include "Index/LCTermInfosReader.h"
#include "Util/LCBitVector.h"

@class LCFieldsReader;
@class LCTermVectorsReader;

//static LCTermVectorsReader *tvReader;

@interface LCSegmentReader: LCIndexReader
{
	NSString *segment;
	LCFieldInfos *fieldInfos;
	LCFieldsReader *fieldsReader;
	LCTermInfosReader *tis;
	LCTermVectorsReader *termVectorsReaderOrig;
	//ThreadLocal termVectorsLocal = new ThreadLocal;
	LCBitVector *deletedDocs;
	BOOL deletedDocsDirty;
	BOOL normsDirty;
	BOOL undeleteAll;
	
	NSMutableDictionary *norms;
	
	LCIndexInput *freqStream;
	LCIndexInput *proxStream;
	LCCompoundFileReader *cfsReader;
}

+ (id) segmentReaderWithInfo: (LCSegmentInfo *) si;
+ (id) segmentReaderWithInfos: (LCSegmentInfos *) sis 
                         info: (LCSegmentInfo *) si
						close: (BOOL) closeDir;
+ (id) segmentReaderWithDirectory: (id <LCDirectory>) dir
							 info: (LCSegmentInfo *) si
							infos: (LCSegmentInfos *) sis
							close: (BOOL) closeDir
							owner: (BOOL) ownDir;
+ (BOOL) hasDeletions: (LCSegmentInfo *) si;
+ (BOOL) usesCompoundFile: (LCSegmentInfo *) si;
+ (BOOL) hasSeparateNorms: (LCSegmentInfo *) si;
- (NSArray *) files;
- (id <LCTermFreqVector>) termFreqVector: (int) docNumber
								   field: (NSString *) field;
- (NSArray *) termFreqVectors: (int) docNumber;
- (LCBitVector*) deletedDocs;
- (LCTermInfosReader *) termInfosReader;
- (LCIndexInput *) freqStream;
- (LCIndexInput *) proxStream;
- (LCFieldInfos *) fieldInfos;
- (NSString *) segment;
- (LCCompoundFileReader *) cfsReader;

@end


#endif /* __LUCENE_INDEX_SEGMENT_READER__ */
