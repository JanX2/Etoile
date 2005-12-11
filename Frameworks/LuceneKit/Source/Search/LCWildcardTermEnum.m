#include "LCWildcardTermEnum.h"
#include "LCIndexReader.h"
#include "GNUstep.h"
#include <OgreKit/OgreKit.h>

@interface LCWildcardTermEnumerator (LCPrivate)
- (BOOL) wildcardEqualsTo: (NSString *) text;
@end

/**
 * Subclass of FilteredTermEnum for enumerating all terms that match the
 * specified wildcard filter term.
 * <p>
 * Term enumerations are always ordered by Term.compareTo().  Each term in
 * the enumeration is greater than all that precede it.
 *
 * @version $Id$
 */

/**
* Creates a new <code>WildcardTermEnum</code>.  Passing in a
 * {@link org.apache.lucene.index.Term Term} that does not contain a
 * <code>WILDCARD_CHAR</code> will cause an exception to be thrown.
 * <p>
 * After calling the constructor the enumeration is already pointing to the first 
 * valid term if such a term exists.
 */

@implementation LCWildcardTermEnumerator

- (id) initWithReader: (LCIndexReader *) reader term: (LCTerm *) term
{
	self = [self init];
	endEnum = NO;
	ASSIGNCOPY(searchTerm, term);
	ASSIGNCOPY(field, [searchTerm field]);
	ASSIGNCOPY(text, [searchTerm text]);
	
	/* Make '*' to be '.*', '?' to be '.?' for regular expression */
	NSMutableString *ms = [[NSMutableString alloc] initWithString: text];
	//NSLog(@"ms %@", ms);
	[ms replaceOccurrencesOfRegularExpressionString: @"\\*"
										 withString: @"\\.\\*"
											options: 0
											  range: NSMakeRange(0, [ms length])];
	[ms replaceOccurrencesOfRegularExpressionString: @"\\?"
										 withString: @"\\.\\+"
											options: 0
											  range: NSMakeRange(0, [ms length])];
	NSLog(@"converted %@", ms);
	
	ASSIGN(ogre, ([OGRegularExpression regularExpressionWithString: [NSString stringWithFormat: @"^%@$", ms]]));
	AUTORELEASE(ms);
	
	LCTerm *t = [[LCTerm alloc] initWithField: field text: @""];
	LCTermEnumerator *e = [reader termEnumeratorWithTerm: t];
	[self setEnumerator: e];
	AUTORELEASE(t);
	//AUTORELEASE(e);  // FIXME: cause segment fault
	return self;
}

- (BOOL) isEqualToTerm: (LCTerm *) term
{
	if ([field isEqualToString: [term field]])
	{
		return [self wildcardEqualsTo: [term text]];
	}
	endEnum = YES;
	return NO;
}

- (float) difference
{
	return 1.0f;
}

- (BOOL) endOfEnumerator
{
	return endEnum;
}

/* Use OgreKit to match wildcard */
- (BOOL) wildcardEqualsTo: (NSString *) t
{
	OGRegularExpressionMatch *match;
	if ((match = [ogre matchInString: t]))
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void) close
{
	[super close];
	DESTROY(searchTerm);
	DESTROY(field);
	DESTROY(text);
	DESTROY(ogre);
}

@end
