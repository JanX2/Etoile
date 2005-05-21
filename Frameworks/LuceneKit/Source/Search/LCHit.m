#include <LuceneKit/Search/LCHit.h>
#include <LuceneKit/Search/LCHits.h>
#include <LuceneKit/Document/LCDocument.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@interface LCHit (LCPrivate)
- (void) fetchTheHit;
@end

@implementation LCHit

- (id) init
{
	self = [super init];
	doc = nil;
	resolved = NO;
	hits = nil;
	return self;
}

- (id) initWithHits: (LCHits *) h index: (int) index
{
	self = [self init];
	ASSIGN(hits, h);
	hitNumber = index;
	return self;
}

- (LCDocument *) document
{
	if (!resolved) [self fetchTheHit];
	return doc;
}

- (float) score
{
	if (!resolved) [self fetchTheHit];
	return score;
}

- (int) identifier
{
	if (!resolved) [self fetchTheHit];
	return identifier;
}

- (void) fetchTheHit
{
	doc = [hits document: hitNumber];
	score = [hits score: hitNumber];
	identifier = [hits identifier: hitNumber];
	resolved = YES;
}

- (float) boost
{
	return [[self document] boost];
}

- (NSString *) stringValue: (NSString *) name
{
	return [[self document] stringValue: name];
}

- (NSString *) description
{
	NSMutableString *buffer = [[NSMutableString alloc] init];
	[buffer appendFormat: @"Hit<%@ [%d] ", hits, hitNumber];
	if (resolved) {
		[buffer appendString: @"resolved>"];
	} else {
		[buffer appendString: @"unresolved>"];
	}
	return AUTORELEASE(buffer);
}

@end

