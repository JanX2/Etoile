#ifndef __LUCENE_INDEX_SEGMENT_READER__
#define __LUCENE_INDEX_SEGMENT_READER__

#include "LuceneKit/Index/LCIndexReader.h"
#include "LuceneKit/Store/LCDirectory.h"
#include "LuceneKit/Index/LCTermFreqVector.h"

@class LCSegmentReader;

@interface LCNorm: NSObject
{
  LCSegmentReader *reader;
  LCIndexInput *input;
  NSMutableData *bytes;
  BOOL dirty;
  int number;
}

- (id) initWithSegmentReader: (LCSegmentReader *) r
        indexInput: (LCIndexInput *) input number: (int) number;
- (void) rewrite;
- (LCIndexInput *) input;
- (BOOL) dirty;
- (void) setDirty: (BOOL) d;
- (NSData *) bytes;
- (void) setBytes: (NSData *) bytes;
@end

@class LCFieldInfos;
@class LCCompoundFileReader;
@class LCSegmentInfo;
@class LCFieldsReader;
@class LCTermVectorsReader;
@class LCTermInfosReader;
@class LCBitVector;

static LCTermVectorsReader *tvReader;

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
- (void) initWithSegmentInfo: (LCSegmentInfo *) si;
+ (BOOL) hasDeletions: (LCSegmentInfo *) si;
+ (BOOL) usesCompoundFile: (LCSegmentInfo *) si;
+ (BOOL) hasSeparateNorms: (LCSegmentInfo *) si;
- (NSArray *) files;
- (void) openNorms: (id <LCDirectory>) cfsDir;
- (void) closeNorms;
- (LCTermVectorsReader *) termVectorsReader;
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
