#ifndef __LUCENE_INDEX_SEGMENT_INFOS__
#define __LUCENE_INDEX_SEGMENT_INFOS__

#include <Foundation/Foundation.h>
#include "LuceneKit/Store/LCDirectory.h"

@class LCSegmentInfo;

@interface LCSegmentInfos: NSObject
{
  int counter; // used to name new segments
  long version; //counts how often the index has been changed by adding or deleting docs
  NSMutableArray *segments;
}

- (LCSegmentInfo *) segmentInfoAtIndex: (int) i;
- (void) readFromDirectory: (id <LCDirectory>) directory;
- (void) writeToDirectory: (id <LCDirectory>) directory;
- (long) version;
- (int) numberOfSegments;
- (void) removeSegmentsInRange: (NSRange) range;
+ (long) currentVersion: (id <LCDirectory>) directory;
- (void) addSegmentInfo: (id) object;
- (int) counter;
- (int) increaseCounter; // counter++

@end
#endif /* __LUCENE_INDEX_SEGMENT_INFOS__ */
