/**	<title>ETXHTMLWriter</title>

	<abstract>XHTML format writer</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>


@interface ETXHTMLWriter : ETXMLWriter 
{
	NSString *title;
}

- (id) initWithTitle: (NSString *)aTitle;

/* Convenience Methods */

- (void) startElement: (NSString *)aName;
- (void) element: (NSString *)aName attributes: (NSDictionary *)attributes;

/* Basic Document Generation */

- (void) startDocument;
- (void) endDocument;

/* Widget Generation */

- (void) startWidgetTable;
- (void) endWidgetTable;
- (void) inputWithType: (NSString *)aWidgetType value: (id)aValue;
- (void) textFieldWithObjectValue: (id)aValue width: (float)aWidth;


@end
