#include "Index/LCSegmentTermDocs.h"
#include "Index/LCSegmentTermEnum.h"
#include "Index/LCSegmentReader.h"
#include "Index/LCTermInfosReader.h"
#include "Index/LCTermInfo.h"
#include "Store/LCIndexInput.h"
#include "Util/LCBitVector.h"
#include "GNUstep/GNUstep.h"

@implementation LCSegmentTermDocs

- (id) initWithSegmentReader: (LCSegmentReader *) p
{
  self = [super init];
  doc = 0;
  ASSIGN(parent, p);
  ASSIGN(freqStream, [[parent freqStream] copy]);
  ASSIGN(deletedDocs, [parent deletedDocs]);
  skipInterval = [[parent termInfosReader] skipInterval];
  return self;
}

- (void) seekTerm: (LCTerm *) term
{
  LCTermInfo *ti = [[parent termInfosReader] termInfo: term];
  [self seekTermInfo: ti];
}

- (void) seekTermEnum: (LCTermEnum *) termEnum
{
  LCTermInfo *ti;
    
    // use comparison of fieldinfos to verify that termEnum belongs to the same segment as this SegmentTermDocs
  if ([termEnum isKindOfClass: [LCSegmentTermEnum class]] &&
      [(LCSegmentTermEnum *)termEnum fieldInfos] == [parent fieldInfos])
      // optimized case
      ti = [(LCSegmentTermEnum *)termEnum termInfo];
    else                                          // punt case
      ti = [[parent termInfosReader] termInfo: [termEnum term]];
      
    [self seekTermInfo: ti];
}

- (void) seekTermInfo: (LCTermInfo *) ti
{
    count = 0;
    if (ti == nil) {
      df = 0;
    } else {
      df = [ti docFreq];
      doc = 0;
      skipDoc = 0;
      skipCount = 0;
      numSkips = df / skipInterval;
      freqPointer = [ti freqPointer];
      proxPointer = [ti proxPointer];
      skipPointer = freqPointer + [ti skipOffset];
      [freqStream seek: freqPointer];
      haveSkipped = NO;
    }
  }

- (void) close
{
    [freqStream close];
    if (skipStream != nil)
      [skipStream close];
  }

- (int) doc
{
  return doc;
}

- (int) freq
{
  return freq;
}

- (void) skippingDoc
{
}

- (BOOL) next
{
    while (YES) {
      if (count == df)
        return NO;

      int docCode = [freqStream readVInt];
      doc += docCode >> 1; //doc += docCode >>> 1;  // shift off low bit
      if ((docCode & 1) != 0)			  // if low bit is set
        freq = 1;				  // freq is one
      else
        freq = [freqStream readVInt];		  // else read freq

      count++;

      if (deletedDocs ==  nil|| ![deletedDocs getBit: doc])
        break;
      [self skippingDoc];
    }
    return YES;
  }

  /** Optimized implementation. */
- (int) readDocs: (NSMutableArray *) docs frequency: (NSMutableArray *) freqs
{
    int length = [docs count];
    int i = 0;
    while (i < length && count < df) {

      // manually inlined call to next() for speed
      int docCode = [freqStream readVInt];
      doc += docCode >> 1; //doc += docCode >>> 1;	  // shift off low bit
      if ((docCode & 1) != 0)			  // if low bit is set
        freq = 1;				  // freq is one
      else
        freq = [freqStream readVInt];		  // else read freq
      count++;

      if (deletedDocs == nil|| ![deletedDocs getBit: doc]) {
	[docs replaceObjectAtIndex: i withObject: [NSNumber numberWithInt: doc]];
	[freqs replaceObjectAtIndex: i withObject: [NSNumber numberWithInt: freq]];
        ++i;
      }
    }
    return i;
  }

  /** Overridden by SegmentTermPositions to skip in prox stream. */
- (void) skipProx: (long) proxPointer
{
}

  /** Optimized implementation. */
- (BOOL) skipTo: (int) target
{
    if (df >= skipInterval) {                      // optimized case

      if (skipStream == nil)
        skipStream = (LCIndexInput*) [freqStream copy]; // lazily clone

      if (!haveSkipped) {                          // lazily seek skip stream
        [skipStream seek: skipPointer];
        haveSkipped = YES;
      }

      // scan skip data
      int lastSkipDoc = skipDoc;
      long lastFreqPointer = [freqStream filePointer];
      long lastProxPointer = -1;
      int numSkipped = -1 - (count % skipInterval);

      while (target > skipDoc) {
        lastSkipDoc = skipDoc;
        lastFreqPointer = freqPointer;
        lastProxPointer = proxPointer;
        
        if (skipDoc != 0 && skipDoc >= doc)
          numSkipped += skipInterval;
        
        if(skipCount >= numSkips)
          break;

        skipDoc += [skipStream readVInt];
        freqPointer += [skipStream readVInt];
        proxPointer += [skipStream readVInt];

        skipCount++;
      }
      
      // if we found something to skip, then skip it
      if (lastFreqPointer > [freqStream filePointer]) {
        [freqStream seek: lastFreqPointer];
        [self skipProx: lastProxPointer];

        doc = lastSkipDoc;
        count += numSkipped;
      }

    }

    // done skipping, now just scan
    do {
      if (![self next])
        return NO;
    } while (target > doc);
    return YES;
 }

@end
