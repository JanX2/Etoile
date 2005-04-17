#ifndef __LUCENE_INDEX_TERM_VECTOR_READER__
#define __LUCENE_INDEX_TERM_VECTOR_READER__

#include <Foundation/Foundation.h>
#include "Index/LCTermFreqVector.h"
#include "Index/LCFieldInfos.h"

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
- (id <LCTermFreqVector>) termFreqVectorWithDocument: (int) docNum
	                           field: (NSString *) field;
- (NSArray *) termFreqVectorsWithDocument: (int) docNum;

@end
#endif /* __LUCENE_INDEX_TERM_VECTOR_READER__ */
