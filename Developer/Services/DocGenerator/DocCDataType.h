/** <title>DocConstant</title>

	<abstract>C data types in the doc element tree.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocElement.h"
#import "GSDocParser.h"

/** DocCDataType objects are used to represent various C data types:

<ul>
<li>structure</li>
<li>function pointer</li>
</ul> 

Enum and union are represented with DocConstant. */
@interface DocCDataType : DocElement <GSDocParserDelegate>
{
	NSString *type;
	NSString *GSDocElementName;
}

/** The underlying type such as struct, enum, NSString const * etc. */
@property (retain, nonatomic) NSString * type;
/** Returns whether the current -type is constant-like. e.g. enum or union. */
@property (readonly) BOOL isConstant;

/** @taskunit GSDoc Parsing */

/** <override-dummy />
Returns the GSDoc element name to be parsed to initialize the instance.

By default, returns <em>type<em>. */
- (NSString *) GSDocElementName;
/** <override-dummy />
Returns the selector matching a CodeDocWeaving method, that should be used to 
weave the receiver into a page.

The returned selector must take a single argument.

e.g. -[(CodeDocWeaving) weaveOtherDataType:] or -[(CodeDocWeaving) weaveConstant:]. */
- (SEL) weaveSelector;

@end


/** DocConstant objects are used to represent various constant-like C data types:

<ul>
<li>const variable or pointer</li>
<li>enum</li>
<li>union</li>
</ul>  */
@interface DocConstant : DocCDataType
{

}

@end