#include "Index/LCSegmentMergeQueue.h"
#include "Index/LCSegmentMergeInfo.h"
#include "Index/LCTerm.h"

@implementation LCSegmentMergeQueue

- (BOOL) lessThan: (id) a : (id) b
{
  LCSegmentMergeInfo *stiA = (LCSegmentMergeInfo *)a;
  LCSegmentMergeInfo *stiB = (LCSegmentMergeInfo *)b;
  int comparison = [[stiA term] compare: [stiB term]];
    if (comparison == 0)
      return [stiA base] < [stiB base]; 
    else
      return comparison < 0;
  }

- (void) close
{
    while ([self top] != nil)
      [((LCSegmentMergeInfo *)[self pop]) close];
}

@end
