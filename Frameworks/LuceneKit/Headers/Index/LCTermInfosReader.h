#ifndef __LUCENE_INDEX_TERM_INFOS_READER__
#define __LUCENE_INDEX_TERM_INFOS_READER__

#include <Foundation/Foundation.h>
#include "LuceneKit/Store/LCDirectory.h"

@class LCFieldInfos;
@class LCSegmentTermEnum;
@class LCTerm;
@class LCTermInfo;

@interface LCTermInfosReader: NSObject
{
  id <LCDirectory> directory;
  NSString *segment;
  LCFieldInfos *fieldInfos;
  LCSegmentTermEnum *origEnum;
  long size;

  NSMutableArray *indexTerms; // LCTerm
  NSMutableArray *indexInfos;  // LCTermInfo
  NSMutableArray *indexPointers; // NSNumber int

  LCSegmentTermEnum *indexEnum;
}

- (id) initWithDirectory: (id <LCDirectory>) dir
                segment: (NSString *) seg
		   fieldInfos: (LCFieldInfos *) fis;
- (int) skipInterval;
- (void) close;
- (long) size;
- (LCSegmentTermEnum *) termEnum;
- (void) ensureIndexIsRead;
- (int) indexOffset: (LCTerm *) term;
- (void) seekEnum: (int) indexOffset;
- (LCTermInfo *) termInfo: (LCTerm *) term;
- (LCTermInfo *) scanEnum: (LCTerm *) term;
- (LCTerm *) termAtPosition: (int) position;
- (LCTerm *) scanEnumAtPosition: (int) position;
- (long) positionOfTerm: (LCTerm *) term;
- (LCSegmentTermEnum *) terms;
- (LCSegmentTermEnum *) termsWithTerm: (LCTerm *) term;

@end

#endif /* __LUCENE_INDEX_TERM_INFOS_READER__ */
