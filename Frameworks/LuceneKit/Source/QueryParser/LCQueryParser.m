#include <LuceneKit/QueryParser/LCQueryParser.h>
#include <LuceneKit/Search/LCBooleanQuery.h>
#include <LuceneKit/Search/LCPrefixQuery.h>
#include <LuceneKit/Search/LCTermQuery.h>
#include <LuceneKit/LCMetadataAttribute.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@implementation LCQueryParser

+ (LCQuery *) parse: (NSString *) query
{
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
}

@end

