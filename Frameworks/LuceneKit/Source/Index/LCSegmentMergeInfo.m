#include "Index/LCSegmentMergeInfo.h"
#include "Index/LCTerm.h"
#include "Index/LCTermEnum.h"
#include "Index/LCIndexReader.h"
#include "GNUstep/GNUstep.h"

@implementation LCSegmentMergeInfo
- (id) initWithBase: (int) b termEnum: (LCTermEnum *) te
              reader: (LCIndexReader *) r
{
  self = [super init];
  base = b;
  ASSIGN(reader, r);
  ASSIGN(termEnum, te);
  term = [te term];
  postings = [reader termPositions];

    // build array which maps document numbers around deletions 
  if ([reader hasDeletions]) {
      int maxDoc = [reader maxDoc];
      ASSIGN(docMap, [[NSMutableArray alloc] init]);
      int j = 0;
      int i;
      for (i = 0; i < maxDoc; i++) {
        if ([reader isDeleted: i])
	  [docMap addObject: [NSNumber numberWithInt: -1]];
        else
	  [docMap addObject: [NSNumber numberWithInt: j++]];
      }
    }
  return self;
}

- (BOOL) next
{
    if ([termEnum next]) {
      term = [termEnum term];
      return YES;
    } else {
      term = nil;
      return NO;
    }
}

- (void) close
{
    [termEnum close];
    [postings close];
}

- (LCTerm *) term { return term; }
- (LCTermEnum *) termEnum { return termEnum; }
- (int) base { return base; }
- (NSArray *) docMap { return docMap; }
- (id <LCTermPositions>) postings { return postings; }

@end
