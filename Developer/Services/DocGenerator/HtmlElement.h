//
//  HtmlElement.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

// FIXME: To turn off the array macro from EtoileFoundation
#if defined(A)
#undef A
#endif

@interface HtmlElement : NSObject {
  NSString* elementName;
  NSMutableDictionary* attributes;
  NSMutableArray* children;
}
+ (HtmlElement*) elementWithName: (NSString*) aName;
- (HtmlElement*) iniWithName: (NSString*) aName;
- (HtmlElement*) addText: (NSString*) aText;
- (HtmlElement*) add: (HtmlElement*) anElem;
- (HtmlElement*) id: (NSString*) anID;
- (HtmlElement*) class: (NSString*) aClass;
- (HtmlElement*) name: (NSString*) aName;
- (HtmlElement*) with: (id) something;
- (HtmlElement*) and: (id) something;
- (NSString*) content;

@end

#define H HtmlElement*
#define HTML [HtmlElement elementWithName: @"html"]
#define DIV [HtmlElement elementWithName: @"div"]
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


@interface HtmlElement (CommonUseCases)
- (HtmlElement *) class: (NSString *)aClass with: (id)something;
- (HtmlElement *) class: (NSString *)aClass with: (id)something and: (id) something;
- (HtmlElement *) class: (NSString *)aClass with: (id)something and: (id) something and: (id)something;
- (HtmlElement *) with: (id)something and: (id) something;
- (HtmlElement *) with: (id)something and: (id) something and: (id)something;
- (HtmlElement *) id: (NSString *)anID with: (id)something;
- (HtmlElement *) id: (NSString *)anID with: (id)something and: (id)something;
@end
