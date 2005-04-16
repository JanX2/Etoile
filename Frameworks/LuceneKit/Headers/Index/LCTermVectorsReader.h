#ifndef __LUCENE_INDEX_TERM_VECTOR_READER__
#define __LUCENE_INDEX_TERM_VECTOR_READER__

#include <Foundation/Foundation.h>
#include "Index/LCTermFreqVector.h"
#include "Store/LCDirectory.h"

@class LCFieldInfos;
@class LCIndexInput;
@class LCSegmentTermVector;

@interface LCTermVectorsReader: NSObject <NSCopying>
{
  LCFieldInfos *fieldInfos;
  LCIndexInput *tvx, *tvd, *tvf;
  long size, tvdFormat, tvfFormat;;
}

- (id) initWithDirectory: (id <LCDirectory>) d
                 segment: (NSString *) segment
	      fieldInfos: (LCFieldInfos *) fieldInfos;
- (void) close;
- (int) size;
- (id <LCTermFreqVector>) termFreqVectorWithDoc: (int) docNum
	                           field: (NSString *) field;
- (NSArray *) termFreqVectorsWithDoc: (int) docNum;

@end
#endif /* __LUCENE_INDEX_TERM_VECTOR_READER__ */
