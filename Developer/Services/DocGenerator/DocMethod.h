/**
	<abstract>Methods in the doc element tree.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "GSDocParser.h"
#import "DocElement.h"

/** @group Doc Element Tree

A DocMethod object represents a method in the documentation element tree. */
@interface DocMethod : DocSubroutine <GSDocParserDelegate>
{
	@private
	BOOL isClassMethod;
	NSMutableArray *selectorKeywords;
	NSString *category;
	NSString *description;
}

/** @taskunit Method Kind */

/** Returns NO when the receiver represents an instance method, otherwise 
returns YES. */ 
- (BOOL) isClassMethod;

/** @taskunit Link Generation */

/** Returns a valid ETDoc method link, relative to the current class in the 
documentation page, that can be turned into a real link in the output 
representation such as HTML.

For example, would return <em>-refMarkup</em> for this method.

-[DocElement insertLinksWithDocIndex:forString:] can detect the links returned 
by these refMarkupXXX methods and hand them to a HTMLDocIndex, which in turn 
will return a HTML link to replace this markup.  */
- (NSString *) refMarkup;
/** Returns a valid ETDoc method link, relative to the given class, that can be 
turned into a real link in the output representation such as HTML.

For example, would return <em>-[DocMethod refMarkup]</em> for this method.

See also -refMarkup. */
- (NSString *) refMarkupWithClassName: (NSString *)aClassName;
/** Returns a valid ETDoc method link, relative to the given protocol, that can 
be turned into a real link in the output representation such as HTML.

For example, would return <em>-[(DocMethod) refMarkup]</em> for this method.

See also -refMarkup. */
- (NSString *) refMarkupWithProtocolName: (NSString *)aProtocolName;

@end
