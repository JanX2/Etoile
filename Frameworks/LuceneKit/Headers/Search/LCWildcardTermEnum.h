#ifndef __LuceneKit_Wildcard_TermEnum__
#define __LuceneKit_Wildcard_TermEnum__

#include <LuceneKit/Search/LCFilteredTermEnum.h>

@class OGRegularExpression;
@class LCTerm;
@class LCIndexReader;

@interface LCWildcardTermEnumerator: LCFilteredTermEnumerator
{
	LCTerm *searchTerm;
	NSString *field;
	NSString *text;
	BOOL endEnum;
	
	OGRegularExpression *ogre;
}

- (id) initWithReader: (LCIndexReader *) reader term: (LCTerm *) term;

@end

#endif /* __LuceneKit_Wildcard_TermEnum__ */
