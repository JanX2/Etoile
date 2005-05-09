#include "Search/LCQueryFilter.h"
#include "Search/LCHitCollector.h"
#include "Search/LCIndexSearcher.h"
#include "Util/LCBitVector.h"
#include "GNUstep/GNUstep.h"

@interface LCQueryFilterHitCollector: LCHitCollector
{
	LCBitVector * bits;
}
- (id) initWithBits: (LCBitVector *) bits;
@end

@implementation LCQueryFilterHitCollector: LCHitCollector
- (id) initWithBits: (LCBitVector *) b
{
	self = [self init];
	ASSIGN(bits, b);
	return self;
}

- (void) collect: (int) doc score: (float) score
{
	[bits setBit: doc];
}
@end

@implementation LCQueryFilter
- (id) initWithQuery: (LCQuery *) q
{
	self = [self init];
	cache = nil;
	ASSIGN(query, q);
	return self;
}

- (LCBitVector *) bits: (LCIndexReader *) reader
{
	if (cache == nil)
	{
		cache = [[NSMutableDictionary alloc] init];
	}
	
	LCBitVector *cached = [cache objectForKey: reader];
	if (cached != nil) return cached;
	
	LCBitVector *bits = [[LCBitVector alloc] initWithSize: [reader maximalDocument]];
	LCQueryFilterHitCollector *hc = [[LCQueryFilterHitCollector alloc] initWithBits: bits];
	LCIndexSearcher *searcher = [[LCIndexSearcher alloc] initWithReader: reader];
	[searcher search: query hitCollector: hc];
	[cache setObject: bits forKey: reader];
	RELEASE(searcher);
	RELEASE(hc);
	
	return AUTORELEASE(bits);
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"LCQueryFilter(%@)", query];
}

@end
