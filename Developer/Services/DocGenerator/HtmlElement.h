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
@interface HtmlElement : NSObject 
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
+ (HtmlElement *) blankElement;
+ (HtmlElement *) elementWithName: (NSString *) aName;
- (HtmlElement *) initWithName: (NSString *) aName;
- (HtmlElement *) addText: (NSString *) aText;
- (HtmlElement *) add: (HtmlElement *) anElem;
- (HtmlElement *) id: (NSString *) anID;
- (HtmlElement *) class: (NSString *) aClass;
- (HtmlElement *) name: (NSString *) aName;
- (HtmlElement *) with: (id) something;
- (HtmlElement *) and: (id) something;
- (NSString *) content;
/** Returns -content. */
- (NSString  *) description;

@end

#define H HtmlElement*
#define HTML [HtmlElement elementWithName: @"html"]
#define DIV [HtmlElement elementWithName: @"div"]
#define SPAN [HtmlElement elementWithName: @"span"]
#define H1 [HtmlElement elementWithName: @"h1"]
#define H2 [HtmlElement elementWithName: @"h2"]
#define H3 [HtmlElement elementWithName: @"h3"]
#define H4 [HtmlElement elementWithName: @"h4"]
#define H5 [HtmlElement elementWithName: @"h5"]
#define H6 [HtmlElement elementWithName: @"h6"]
#define I [HtmlElement elementWithName: @"i"]
#define A [HtmlElement elementWithName: @"a"]
#define P [HtmlElement elementWithName: @"p"]
#define TABLE [HtmlElement elementWithName: @"table"]
#define TR [HtmlElement elementWithName: @"tr"]
#define TD [HtmlElement elementWithName: @"td"]
#define TH [HtmlElement elementWithName: @"th"]
#define DL [HtmlElement elementWithName: @"dl"]
#define DT [HtmlElement elementWithName: @"dt"]
#define DD [HtmlElement elementWithName: @"dd"]
#define UL [HtmlElement elementWithName: @"ul"]
#define LI [HtmlElement elementWithName: @"li"]
#define EM [HtmlElement elementWithName: @"em"]
#define HR [HtmlElement elementWithName: @"hr"]

/** @group HTML Support */
@interface HtmlElement (CommonUseCases)
- (HtmlElement *) class: (NSString *)aClass with: (id)something;
- (HtmlElement *) class: (NSString *)aClass with: (id)something and: (id) something;
- (HtmlElement *) class: (NSString *)aClass with: (id)something and: (id) something and: (id)something;
- (HtmlElement *) with: (id)something and: (id) something;
- (HtmlElement *) with: (id)something and: (id) something and: (id)something;
- (HtmlElement *) with: (id)something and: (id) something and: (id)something and: (id)something;
- (HtmlElement *) id: (NSString *)anID with: (id)something;
- (HtmlElement *) id: (NSString *)anID with: (id)something and: (id)something;
- (HtmlElement *) id: (NSString *)anID with: (id)something and: (id)something and: (id)something;
@end
