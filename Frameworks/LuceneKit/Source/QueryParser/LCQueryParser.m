#include "LCQueryParser.h"
#include "LCBooleanQuery.h"
#include "LCPrefixQuery.h"
#include "LCTermQuery.h"
#include "LCMetadataAttribute.h"
#include "GNUstep.h"
#include "CodeParser.h"
#include "QueryHandler.h"

@implementation LCQueryParser

+ (LCQuery *) parse: (NSString *) query
{
#if 1
  QueryHandler *handler = [[QueryHandler alloc] init];
  CodeParser *parser = [[CodeParser alloc] initWithCodeHandler: handler withString: query];
  [parser parse];
//  NSLog(@"%@", [handler query]);
  return [handler query];
#else
	NSArray *subclauses = [query componentsSeparatedByString: @" "];
	
	LCBooleanQuery *bq = [[LCBooleanQuery alloc] init];
    int i;
    for (i = 0; i < [subclauses count]; i++)
    {
		LCOccurType occur = LCOccur_SHOULD;
		NSString *text = nil;
		if ([[subclauses objectAtIndex: i] hasPrefix: @"+"]) {
			occur = LCOccur_MUST;
			ASSIGN(text, [[subclauses objectAtIndex: i] substringFromIndex: 1]);
		} else if ([[subclauses objectAtIndex: i] hasPrefix: @"-"]) {
			occur = LCOccur_MUST_NOT;
			ASSIGN(text, [[subclauses objectAtIndex: i] substringFromIndex: 1]);
		} else {
			occur = LCOccur_SHOULD;
			ASSIGNCOPY(text, [subclauses objectAtIndex: i]);
		}
		LCTerm *term;
		LCQuery *tq;
		/* Search LCTextContentAttribute by default */
		if ([text hasSuffix: @"*"]) 
		{
			term = [[LCTerm alloc] initWithField: LCTextContentAttribute
											text: [text substringToIndex: [text length]-1]];
			tq = [[LCPrefixQuery alloc] initWithTerm: term];
		} 
		else
		{ 
			term = [[LCTerm alloc] initWithField: LCTextContentAttribute
											text: text];
			tq = [[LCTermQuery alloc] initWithTerm: term];
		}
		[bq addQuery: tq occur: occur];
		DESTROY(term);
		DESTROY(tq);
    }
	
	return bq;
#endif
}

@end

