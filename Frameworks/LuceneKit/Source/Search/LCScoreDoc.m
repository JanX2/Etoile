#include "Search/LCScoreDoc.h"

@implementation LCScoreDoc

- (id) initWithDocument: (int) d score: (float) s
{
  self = [super init];
  score = s;
  doc = d;
  return self;
}

- (float) score { return score; }
- (void) setScore: (float) s { score = s; }
- (int) document { return doc; }

- (NSComparisonResult) compare: (LCScoreDoc *) other
{
  if ([self score] == [other score])
  {
    if ([self document] < [other document])
      return NSOrderedAscending;
    else if ([self document] == [other document])
      return NSOrderedSame;
    else
      return NSOrderedDescending;
  }
  else if ([self score] < [other score])
  {
    return NSOrderedAscending;
  }
  else
  {
    return NSOrderedDescending;
  }
}

@end
