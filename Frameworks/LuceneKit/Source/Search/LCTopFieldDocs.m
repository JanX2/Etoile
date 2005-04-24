#include "Search/LCTopFieldDocs.h"
#include "GNUstep/GNUstep.h"

@implementation LCTopFieldDocs
- (id) initWithTotalHits: (int) th
       scoreDocuments: (NSArray *) sd
           sortFields: (NSArray *) f
{
  self = [self initWithTotalHits: th scoreDocuments: sd];
  ASSIGN(fields, f);
  return self;
}

- (void) dealloc
{
  DESTROY(fields);
  [super dealloc];
}
@end
