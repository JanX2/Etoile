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

/** @group HTML Support */
@interface DocHTMLElement : NSObject 
{
	NSString* elementName;
	NSMutableDictionary* attributes;
	NSMutableArray* children;
	NSSet *blockElementNames;
}
/** Returns a new HTML element whose content is not wrapped into opening and 
closing tags corresponding to the receiver, but limited to the child content.

When the content is evaluated, the element name and attributes are ignored, but 
each child content is evaluated normally.

When the receiver has no children, -content returns an empty string. */
+ (DocHTMLElement *) blankElement;
+ (DocHTMLElement *) elementWithName: (NSString *) aName;
- (DocHTMLElement *) initWithName: (NSString *) aName;
- (DocHTMLElement *) addText: (NSString *) aText;
- (DocHTMLElement *) add: (DocHTMLElement *) anElem;
- (DocHTMLElement *) id: (NSString *) anID;
- (DocHTMLElement *) class: (NSString *) aClass;
- (DocHTMLElement *) name: (NSString *) aName;
- (DocHTMLElement *) with: (id) something;
- (DocHTMLElement *) and: (id) something;
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

/** @group HTML Support */
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
