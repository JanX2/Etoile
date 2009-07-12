/**	<title>ETXHTMLRenderContext</title>

	<abstract>Transform class to export any layout item tree to XHTML</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>

@class ETXHTMLWriter;
@class ETDecoratorItem, ETLayoutItem, ETLayoutItemGroup, ETScrollableAreaItem, 
	ETWindowItem;

@interface ETXHTMLRendering : ETTransform
{
	ETXHTMLWriter *writer;
}

+ (id) render: (id)anObject;
- (id) initWithWriter: (ETXHTMLWriter *)aWriter;

@end


@interface ETXHTMLRenderContext : ETXHTMLRendering
{

}

+ (id) contextWithWriter: (ETXHTMLWriter *)aWriter;

- (id) render: (id)anObject;

/* Layout Item Rendering */

- (void) renderItem: (ETLayoutItem *)anItem;
- (void) renderItemGroup: (ETLayoutItemGroup *)anItem;

/* Decorator Item Rendering */

- (void) renderDecoratorItem: (ETDecoratorItem *)aDecorator;
- (void) renderWindowItem: (ETWindowItem *)anItem;
- (void) renderScrollableAreaItem: (ETScrollableAreaItem *)anItem;

@end
