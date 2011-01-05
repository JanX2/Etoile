/**
	<abstract>Macros in the doc element tree.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Authors:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2010
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "GSDocParser.h"
#import "DocFunction.h"

@class HtmlElement;

/** @group Doc Element Tree

A DocMacro object represents a macro in the documentation element tree. */
@interface DocMacro : DocFunction
{

}

/** @taskunit GSDoc Parsing */

/** <override-dummy />
Returns <em>macro</em>.

See -[DocElement GSDocElementName]. */
- (NSString *) GSDocElementName;
/** <override-dummy />
Returns -weaveMacro:.

See -[DocElement weaveSelector]. */
- (SEL) weaveSelector;

@end
