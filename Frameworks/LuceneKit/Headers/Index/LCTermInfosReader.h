#ifndef __LUCENE_INDEX_TERM_INFOS_READER__
#define __LUCENE_INDEX_TERM_INFOS_READER__

#include <Foundation/Foundation.h>
#include "Index/LCFieldInfos.h"
#include "Index/LCSegmentTermEnum.h"
#include "Index/LCTerm.h"

@interface LCTermInfosReader: NSObject
{
	id <LCDirectory> directory;
	NSString *segment;
	LCFieldInfos *fieldInfos;
	LCSegmentTermEnum *origEnum;
	unsigned long long size;
	
	NSMutableArray *indexTerms; // LCTerm
	NSMutableArray *indexInfos;  // LCTermInfo
	NSMutableArray *indexPointers; // NSNumber int
	
	LCSegmentTermEnum *indexEnum;
}

- (id) initWithDirectory: (id <LCDirectory>) dir
				 segment: (NSString *) seg
			  fieldInfos: (LCFieldInfos *) fis;
- (int) skipInterval;
- (void) close;
- (long) size;
- (LCTermInfo *) termInfo: (LCTerm *) term;
- (LCTerm *) termAtPosition: (int) position;
- (long) positionOfTerm: (LCTerm *) term;
- (LCSegmentTermEnum *) terms;
- (LCSegmentTermEnum *) termsWithTerm: (LCTerm *) term;

@end

#endif /* __LUCENE_INDEX_TERM_INFOS_READER__ */
