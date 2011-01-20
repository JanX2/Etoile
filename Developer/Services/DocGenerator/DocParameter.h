/**
	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class DocHTMLElement;

/** @group Doc Element Tree
    @abstract Parameters in the doc element tree.

A DocParameter object can be used to represent both method argument, and 
function or macro parameter in the documentation element tree.

This class is used by DocSubroutine class and subclasses such DocMethod, 
DocFunction and DocMacro.

DocParameter can extract class, protocol names, and some type modifiers used 
in prefix or suffix position. See -parseType: which documents the type parsing 
support. */
@interface DocParameter : NSObject
{
	NSString *name;
	NSString *type;
	NSString *description;
	NSString *typePrefix;
	NSString *className;
	NSString *protocolName;
	NSString *typeSuffix;
}

/** @taskunit Initialization and Factory Methods */

/** Returns a new autoreleased parameter with the given name and type. */
+ (id) parameterWithName: (NSString *)aName type: (NSString *)aType;

/** <init />
Initializes and returns a new parameter with the given name and type. */
- (id) initWithName: (NSString *)aName andType: (NSString *)aType;

/** @taskunit Basic Properties */

/** The parameter name. */
@property (retain, nonatomic) NSString *name;
/** The C or ObjC type attached to the parameter. */
@property (retain, nonatomic) NSString *type;
/** An optional description of the parameter role and use. */
@property (retain, nonatomic) NSString *description;

/** @taskunit Type Infos */

- (void) parseType: (NSString *)aType;
/** The prefix found by parsing the type. 

Usually returns nil, except when a class or protocol is declared in -type and 
prefixed with a C type modifier. For example, <em>const NSString *</em>, in 
that case <em>const</em> would be returned. */
@property (readonly, nonatomic) NSString *typePrefix;
/** The class name found by parsing the type.

When no protocol is declared in -type, returns nil. */
@property (readonly, nonatomic) NSString *className;
/** The protocol name found by parsing the type. 

When no protocol is declared in -type, returns nil. */
@property (readonly, nonatomic) NSString *protocolName;
/** The suffix found by parsing the type. 

Usually returns nil, except when a class or protocol is declared in -type and 
suffixed with a C type modifier. For example, <em>NSString * const</em>, in 
that case <em>const</em> would be returned. */
@property (readonly, nonatomic) NSString *typeSuffix;

/** @taskunit HTML Generation */

/** Returns the parameter rendered as a HTML element tree.

When usesParentheses is YES, the ouput will be wrapped into parentheses e.g. 
<em>(NSString *)</em> rather than <em>NSString *</em>.

The ouput includes both the name and the type. */
- (DocHTMLElement *) HTMLRepresentationWithParentheses: (BOOL)usesParentheses;

@end
