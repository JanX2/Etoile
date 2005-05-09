#include "Index/LCSegmentTermDocs.h"
#include "Index/LCSegmentTermEnum.h"
#include "Index/LCTermInfosReader.h"
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

- (void) dealloc
{
	RELEASE(freqStream);
	RELEASE(deletedDocs);
	RELEASE(parent);
	[super dealloc];
}

- (void) seekTerm: (LCTerm *) term
{
	LCTermInfo *ti = [[parent termInfosReader] termInfo: term];
	//  NSLog(@"seekTerm %@: %@", term, ti);
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
		df = [ti documentFrequency];
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

- (long) document
{
	return doc;
}

- (long) frequency
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
		
		long docCode = [freqStream readVInt];
		doc += (docCode >> 1) & 0x7fffffff; //doc += docCode >>> 1;  // shift off low bit
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
- (int) readDocuments: (NSMutableArray *) docs frequency: (NSMutableArray *) freqs
{
    int length = [docs count];
    int i = 0;
    while (i < length && count < df) {
		
		// manually inlined call to next() for speed
		long docCode = [freqStream readVInt];
		doc += (docCode >> 1) & 0x7fffffff; //doc += docCode >>> 1;	  // shift off low bit
		if ((docCode & 1) != 0)			  // if low bit is set
			freq = 1;				  // freq is one
		else
			freq = [freqStream readVInt];		  // else read freq
		count++;
		
		if (deletedDocs == nil|| ![deletedDocs getBit: doc]) {
			[docs replaceObjectAtIndex: i withObject: [NSNumber numberWithLong: doc]];
			[freqs replaceObjectAtIndex: i withObject: [NSNumber numberWithLong: freq]];
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
