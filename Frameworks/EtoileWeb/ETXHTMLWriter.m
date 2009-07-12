/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */
 
#import "ETXHTMLWriter.h"


@implementation ETXHTMLWriter

- (id) initWithTitle: (NSString *)aTitle
{
	SUPERINIT;
	ASSIGN(title, aTitle);
	return self;
}

DEALLOC(DESTROY(title))

/* Convenience Methods */

- (void) startElement: (NSString *)aName
{
	[self startElement: aName attributes: nil];
}

- (void) element: (NSString *)aName attributes: (NSDictionary *)attributes
{
	[self startElement: aName attributes: attributes];
	[self endElement];
}

/* Basic Document Generation */

- (void) startDocument
{
	[self characters: @"<!DOCTYPE html>"]; /* To enable XHTML 5 and higher */
	[self startElement: @"html"];
	[self startElement: @"head"];
	[self startElement: @"title"];
	[self characters: @"title"];
	[self endElement: @"title"];
	[self endElement: @"head"];
	[self startElement: @"body"];
}

- (void) endDocument
{
	[self endElement: @"body"];
	[self endElement: @"html"];
}

- (void) startWidgetTable
{
	[self startElement: @"table" attributes: nil];
}

- (void) endWidgetTable
{
	[self endElement: @"table"];
}

- (void) inputWithType: (NSString *)aWidgetType value: (id)aValue
{
	[self element: @"input" attributes: D(aWidgetType, @"type", aValue, @"value")];
}

- (void) textFieldWithObjectValue: (id)aValue width: (float)aWidth
{
	[self element: @"input" attributes: D(@"text", @"type", 
		aValue, @"value", aWidth, @"size")];
}

@end
