#ifndef __LUCENE_SEARCH_HIT__
#define __LUCENE_SEARCH_HIT__

#include <Foundation/Foundation.h>

@class LCDocument;
@class LCHits;

@interface LCHit: NSObject
{
	float score;
	int identifier;
	LCDocument *doc;
	BOOL resolved;
	LCHits *hits;
	int hitNumber;
}

- (id) initWithHits: (LCHits *) hits index: (int) hitNumber;
- (LCDocument *) document;
- (float) score;
- (int) identifier;
- (void) fetchTheHit;
- (float) boost;
- (NSString *) stringValue: (NSString *) name;

@end

#endif /* __LUCENE_SEARCH_HIT__ */
