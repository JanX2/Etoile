/**
	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

// FIXME: To turn off the array macro from EtoileFoundation
#if defined(A)
#undef A
#endif

/** @group HTML Support
    @abstract HTML element class to output HTML in a concise way.

DocHTMLElement is a Seaside-inspired class that provides a DSL to write compact 
HTML generation code.

DocHTMLElement comes with null-like element that doesn't emit the element markup 
when evaluated. See +blankElement.

TODO: DocHTMLElement DSL should be more clean and formalized. For example, 
-and:, -with: and -add: are the same, but it isn't entirely clear-cut when one 
should be preferred to the others.<br />
For now, a single -with: should be used per message chains. Any subsequent 
concatenation messages should use -and:. e.g. -with:and:and: is valid but 
-with:with:and: is not.<br />
The obscure point is what to do when we send a single concatenation message. 
Should we recommend -with:, -and: or -add:? Should we take in account the type 
of the concatened content such DocHTMLElement or NSString, then make a 
distinction between -add: and -addText:.<br />
Is DocHTMLElement DSL really needed or the right answer to what we need? */
@interface DocHTMLElement : NSObject 
{
	NSString *elementName;
	NSMutableDictionary *attributes;
	NSMutableArray *children;
	NSSet *blockElementNames;
}

/** @taskunit Initialization and Factory Methods */

/** Returns a new HTML element whose content is not wrapped into opening and 
closing tags corresponding to the receiver, but limited to the child content.

When the content is evaluated, the element name and attributes are ignored, but 
each child content is evaluated normally.

When the receiver has no children, -content returns an empty string. */
+ (DocHTMLElement *) blankElement;
+ (DocHTMLElement *) elementWithName: (NSString *) aName;

- (DocHTMLElement *) initWithName: (NSString *) aName;

/** @taskunit HTML Attributes Support */

- (DocHTMLElement *) id: (NSString *) anID;
- (DocHTMLElement *) class: (NSString *) aClass;
- (DocHTMLElement *) name: (NSString *) aName;

/** @taskunit Tree Building Primitives */

- (DocHTMLElement *) addText: (NSString *) aText;
- (DocHTMLElement *) add: (DocHTMLElement *) anElem;

/** @taskunit Tree Building Syntactic Sugar */

- (DocHTMLElement *) with: (id) something;
- (DocHTMLElement *) and: (id) something;

/** @taskunit HTML Generation */

/** Returns the HTML string representation of the element tree rooted in the 
receiver.

This HTML generation is done in a recursive manner by invoking -content on the 
child elements.

TODO: Document a bit better and when line breaks are inserted. */
- (NSString *) content;
/** Returns -content. */
- (NSString  *) description;

@end

#define H DocHTMLElement*
#define HTML [DocHTMLElement elementWithName: @"html"]
#define DIV [DocHTMLElement elementWithName: @"div"]
#define SPAN [DocHTMLElement elementWithName: @"span"]
#define H1 [DocHTMLElement elementWithName: @"h1"]
#define H2 [DocHTMLElement elementWithName: @"h2"]
#define H3 [DocHTMLElement elementWithName: @"h3"]
#define H4 [DocHTMLElement elementWithName: @"h4"]
#define H5 [DocHTMLElement elementWithName: @"h5"]
#define H6 [DocHTMLElement elementWithName: @"h6"]
#define I [DocHTMLElement elementWithName: @"i"]
#define A [DocHTMLElement elementWithName: @"a"]
#define P [DocHTMLElement elementWithName: @"p"]
#define TABLE [DocHTMLElement elementWithName: @"table"]
#define TR [DocHTMLElement elementWithName: @"tr"]
#define TD [DocHTMLElement elementWithName: @"td"]
#define TH [DocHTMLElement elementWithName: @"th"]
#define DL [DocHTMLElement elementWithName: @"dl"]
#define DT [DocHTMLElement elementWithName: @"dt"]
#define DD [DocHTMLElement elementWithName: @"dd"]
#define UL [DocHTMLElement elementWithName: @"ul"]
#define LI [DocHTMLElement elementWithName: @"li"]
#define EM [DocHTMLElement elementWithName: @"em"]
#define HR [DocHTMLElement elementWithName: @"hr"]
#define BR [DocHTMLElement elementWithName: @"br"]

/** @group HTML Support

Category on DocHTMLElement to prevent compiler warning since DocHTMLElement 
has no fixed API but support a large number of message chaining variations.  */
@interface DocHTMLElement (CommonUseCases)
- (DocHTMLElement *) class: (NSString *)aClass with: (id)something;
- (DocHTMLElement *) class: (NSString *)aClass with: (id)something and: (id) something;
- (DocHTMLElement *) class: (NSString *)aClass with: (id)something and: (id) something and: (id)something;
- (DocHTMLElement *) with: (id)something and: (id) something;
- (DocHTMLElement *) with: (id)something and: (id) something and: (id)something;
- (DocHTMLElement *) with: (id)something and: (id) something and: (id)something and: (id)something;
- (DocHTMLElement *) id: (NSString *)anID with: (id)something;
- (DocHTMLElement *) id: (NSString *)anID with: (id)something and: (id)something;
- (DocHTMLElement *) id: (NSString *)anID with: (id)something and: (id)something and: (id)something;
@end
