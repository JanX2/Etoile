#include "LuceneKit/Index/LCSegmentInfo.h"
#include "GNUstep.h"

@implementation LCSegmentInfo

- (id) initWithName: (NSString *) n
       numberOfDocuments: (int) count
       directory: (id <LCDirectory>) d
{
  self = [super init];
  ASSIGN(name, n);
  docCount = count;
  ASSIGN(dir, d);
  return self;
}

- (void) dealloc
{
  RELEASE(name);
  RELEASE(dir);
  [super dealloc];
}

- (NSString *) name
{
  return name;
}

- (int) numberOfDocuments
{
  return docCount;
}

- (id <LCDirectory>) directory
{
  return dir;
}

@end
