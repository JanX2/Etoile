#ifndef __LUCENE_INDEX_TEST_SEGMENT_MERGER__
#define __LUCENE_INDEX_TEST_SEGMENT_MERGER__

#include <UnitKit/UnitKit.h>
#include <Foundation/Foundation.h>
#include "Store/LCDirectory.h"

@class LCDocument;
@class LCSegmentReader;

@interface TestSegmentMerger: NSObject <UKTest>
{
  //The variables for the new merged segment
  id <LCDirectory> mergedDir;
  NSString *mergedSegment;
  //First segment to be merged
  id <LCDirectory> merge1Dir;
  LCDocument *doc1;
  NSString *merge1Segment;
  LCSegmentReader *reader1;
  //Second Segment to be merged
  id <LCDirectory> merge2Dir;
  LCDocument *doc2;
  NSString *merge2Segment;
  LCSegmentReader *reader2;
}

@end

#endif /* __LUCENE_INDEX_TEST_SEGMENT_MERGER__ */
