#ifndef __LUCENE_INDEX_TERM_VECTORS_WRITER__
#define __LUCENE_INDEX_TERM_VECTORS_WRITER__

#include <Foundation/Foundation.h>

#define STORE_POSITIONS_WITH_TERMVECTOR 0x1
#define STORE_OFFSET_WITH_TERMVECTOR 0x2
#define TERM_VECTORS_WRITER_FORMAT_VERSION 2
#define TERM_VECTORS_WRITER_FORMAT_SIZE 4

static NSString *TVX_EXTENSION = @"tvx";
static NSString *TVD_EXTENSION = @"tvd";
static NSString *TVF_EXTENSION = @"tvf";

@interface LCTVField: NSObject
{
  int number;
  long tvfPointer;
  BOOL storePositions;
  BOOL storeOffsets;
}

- (id) initWithNumber: (int) number storePosition: (BOOL) storePos
            storeOffset: (BOOL) storeOff;
- (void) setTVFPointer: (long) p;
- (long) tvfPointer;
- (BOOL) storePositions;
- (BOOL) storeOffsets;
- (int) number;

@end

@interface LCTVTerm: NSObject
{
  NSString *termText;
  int freq;
  NSArray *positions;
  NSArray *offsets;
}
- (void) setTermText: (NSString *) text;
- (void) setFreq: (int) f;
- (void) setPositions: (NSArray *) p;
- (void) setOffsets: (NSArray *) o;
- (NSString *) termText;
- (int) freq;
- (NSArray *) positions;
- (NSArray *) offsets;
@end

#include "LuceneKit/Store/LCDirectory.h"

@class LCIndexOutput;
@class LCFieldInfos;

@interface LCTermVectorsWriter: NSObject
{
  LCIndexOutput *tvx, *tvd, *tvf;
  NSMutableArray *fields;
  NSMutableArray *terms;
  LCFieldInfos *fieldInfos;
  LCTVField *currentField;
  long currentDocPointer;
}
- (id) initWithDirectory: (id <LCDirectory>) directory
                segment: (NSString *) segment
	       fieldInfos: (LCFieldInfos *) fieldInfos;
- (void) openDocument;
- (void) closeDocument;
- (BOOL) isDocumentOpen;
- (void) openField: (NSString *) field;
- (void) openField: (int) fieldNumber
         isPositionWithTermVectorStored: (BOOL) storePositionWithTermVector
	 isOffsetWithTermVectorStored: (BOOL) storeOffsetWithTermVector;
- (void) closeField;
- (BOOL) isFieldOpen;
- (void) addTerm: (NSString *) termText freq: (int) freq;
- (void) addTerm: (NSString *) termText freq: (int) freq
         positions: (NSArray *) positions offsets: (NSArray *) offsets;
- (void) addTermInternal: (NSString *) termText freq: (int) freq
         positions: (NSArray *) positions offsets: (NSArray *) offsets;
- (void) addAllDocVectors: (NSArray *) vectors;
- (void) close;
- (void) writeField;
- (void) writeDoc;

@end
  
#endif /* __LUCENE_INDEX_TERM_VECTORS_WRITER__ */
