#ifndef __LUCENE_INDEX_SEGMENT_TERM_ENUM__
#define __LUCENE_INDEX_SEGMENT_TERM_ENUM__

#include "LuceneKit/Index/LCTermEnum.h"

@class LCIndexInput;
@class LCFieldInfos;
@class LCTermBuffer;
@class LCTermInfo;

@interface LCSegmentTermEnum: LCTermEnum <NSCopying>
{
  LCIndexInput *input;
  LCFieldInfos *fieldInfos;
  long size;
  long position;
  LCTermBuffer *termBuffer, *prevBuffer;
  LCTermBuffer *scratch; // used for scanning
  LCTermInfo *termInfo;

  int format;
  BOOL isIndex;
  long indexPointer;
  int indexInterval;
  unsigned int skipInterval;
  int formatM1SkipInterval;
}

- (id) initWithIndexInput: (LCIndexInput *) i
               fieldInfos: (LCFieldInfos *) fis
                  isIndex: (BOOL) isi;
- (void) seek: (long) pointer position: (int) p
         term: (LCTerm *) t termInfo: (LCTermInfo *) ti;
- (void) scanTo: (LCTerm *) term;
- (LCTerm *) prev;
- (LCTermInfo *) termInfo;
- (void) setTermInfo: (LCTermInfo *) ti;
- (long) freqPointer;
- (long) proxPointer;
- (LCFieldInfos *) fieldInfos;
- (void) setIndexInput: (LCIndexInput *) i;
- (void) setTermBuffer: (LCTermBuffer *) tb;
- (void) setPrevBuffer: (LCTermBuffer *) pb;
- (void) setScratch: (LCTermBuffer *) s;
- (long) size;
- (long) indexPointer;
- (long) position;
- (unsigned int) skipInterval;
- (int) indexInterval;

@end

#endif /* __LUCENE_INDEX_SEGMENT_TERM_ENUM__ */
