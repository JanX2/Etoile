#include "LuceneKit/Index/LCSegmentTermPositions.h"
#include "LuceneKit/Index/LCSegmentReader.h"
#include "LuceneKit/Index/LCTermInfo.h"
#include "LuceneKit/Store/LCIndexInput.h"
#include "GNUstep.h"


@implementation LCSegmentTermPositions

- (id) initWithSegmentReader: (LCSegmentReader *) p
{
  self = [super initWithSegmentReader: p];
  ASSIGN(proxStream, [[p proxStream] copy]);
  return self;
}
  
- (void) seekTermInfo: (LCTermInfo *) ti
{
  [super seekTermInfo: ti];
    if (ti != nil)
	    [proxStream seek: [ti proxPointer]];
    proxCount = 0;
  }

- (void) close
{
  [super close];
  [proxStream close];
  }

- (int) nextPosition
{
    proxCount--;
    return position += [proxStream readVInt];
  }

- (void) skippingDoc
{
  int f;
    for (f = freq; f > 0; f--)		  // skip all positions
      [proxStream readVInt];
  }

- (BOOL) next
{
	int f;
    for (f = proxCount; f > 0; f--)		  // skip unread positions
      [proxStream readVInt];

    if ([super next]) {				  // run super
      proxCount = freq;				  // note frequency
      position = 0;				  // reset position
      return YES;
    }
    return NO;
  }

- (int) readDocs: (NSMutableArray *) docs frequency: (NSMutableArray *) freqs
{
  NSLog(@"TermPositions does not support processing multiple documents in one call. Use TermDocs instead.");
  return -1;
  }


  /** Called by super.skipTo(). */
- (void) skipProx: (long) pp
{
    [proxStream seek: pp];
    proxCount = 0;
  }

@end
