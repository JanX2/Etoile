#include "LCPrefixQuery.h"
#include "LCBooleanQuery.h"
#include "LCTermQuery.h"
#include "LCTermEnum.h"
#include "GNUstep.h"

@implementation LCPrefixQuery

- (id) initWithTerm: (LCTerm *) p
{
	self = [self init];
	ASSIGN(prefix, p);
	return self;
}

- (LCQuery *) rewrite: (LCIndexReader *) reader
{
	LCBooleanQuery *query = [[LCBooleanQuery alloc] initWithCoordination: YES];
	LCTermEnumerator *enumerator = [reader termEnumeratorWithTerm: prefix];
	NSString *prefixText = [prefix text];
	NSString *prefixField = [prefix field];
	do {
		LCTerm *term = [enumerator term];
		if (term != nil &&
			[[term text] hasPrefix: prefixText] &&
			[[term field] isEqualToString: prefixField])
		{
			LCTermQuery *tq = [[LCTermQuery alloc] initWithTerm: term]; // found a match
			[tq setBoost: [self boost]]; // set the boost
			[query addQuery: tq occur: LCOccur_SHOULD]; // add to quer
		} else {
			break;
		}
	} while ([enumerator hasNextTerm]);
	[enumerator close];
	return AUTORELEASE(query);
}

- (void) dealloc
{
	DESTROY(prefix);
	[super dealloc];
}

- (LCTerm *) prefix
{
	return prefix;
}

- (NSString *) descriptionWithField: (NSString *) field
{
	NSMutableString *buffer = [[NSMutableString alloc] init];
	if (![[prefix field] isEqualToString: field])
	{
		[buffer appendFormat: @"%@:", [prefix field]];
    }
	[buffer appendFormat: @"%@*", [prefix text]];
    if ([self boost] != 1.0f) {
		[buffer appendFormat: @"^%f", [self boost]];
    }
	return AUTORELEASE(buffer);
}

@end
