#ifndef __LUCENE_INDEX_TERM_INFOS_WRITER__
#define __LUCENE_INDEX_TERM_INFOS_WRITER__

#include <Foundation/Foundation.h>
#include "LuceneKit/Store/LCDirectory.h"

/** The file format version, a negative number. */
#define LCTermInfos_FORMAT -2

@class LCFieldInfos;
@class LCIndexOutput;
@class LCTerm;
@class LCTermInfo;

@interface LCTermInfosWriter: NSObject
{
  LCFieldInfos *fieldInfos;
  LCIndexOutput *output;
  LCTerm *lastTerm;
  LCTermInfo *lastTi;
  long long size;
  int indexInterval;
  int skipInterval;
  long lastIndexPointer;
  BOOL isIndex;
  LCTermInfosWriter *other;
}

- (id) initWithDirectory: (id <LCDirectory>) directory
                segment: (NSString *) segment
                fieldInfos: (LCFieldInfos *) fis
                interval: (int) interval;
- (id) initWithDirectory: (id <LCDirectory>) directory
                segment: (NSString *) segment
                fieldInfos: (LCFieldInfos *) fis
                interval: (int) interval
		isIndex: (BOOL) isIndex;

- (void) setOther: (LCTermInfosWriter *) other;
- (void) addTerm: (LCTerm *) term termInfo: (LCTermInfo *) ti;
- (LCIndexOutput *) output;
- (void) writeTerm: (LCTerm *) term;
- (void) close;
- (int) skipInterval;

@end

#endif /* __LUCENE_INDEX_TERM_INFOS_WRITER__ */
