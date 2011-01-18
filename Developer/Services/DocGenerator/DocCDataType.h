/**
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

/** 
@group Doc Element Tree
@abstract oui!

-weaveOtherDataType: -[(GSDocParserDelegate) parser:endElement:withContent:] DocCDataType objects are used to represent various C data types:

<list>
<item>structure</item>
<item>function pointer</item>
</list> 

Enum and union are represented with DocConstant -weaveSelector. */
@interface DocCDataType : DocElement <GSDocParserDelegate>
{
	NSString *type;
}

/** The underlying type such as struct, enum, NSString const * etc. */
@property (retain, nonatomic) NSString * type;
/** Returns whether the current -type is constant-like. e.g. enum or union. */
@property (readonly) BOOL isConstant;

/** @taskunit GSDoc Parsing */

/** <override-dummy />
Returns <em>type</em>.

See -[DocElement GSDocElementName].

@param bla
@return bli */
- (NSString *) GSDocElementName;
/** <override-dummy />
Returns -weaveOtherDataType:.

See -[DocElement weaveSelector]. */
- (SEL) weaveSelector;

@end


/** @group Doc Element Tree
@abstract C constant-like types in the doc element tree.

DocConstant objects are used to represent various constant-like C data types:

<list>
<item>const variable or pointer</item>
<item>enum</item>
<item>union</item>
</list>  */
@interface DocConstant : DocCDataType
{

}

/** @taskunit GSDoc Parsing */

/** <override-dummy />
Returns <em>constant</em>.

See -[DocElement GSDocElementName]. */
- (NSString *) GSDocElementName;
/** <override-dummy />
Returns -weaveConstant:.

See -[DocElement weaveSelector]. */
- (SEL) weaveSelector;

@end
