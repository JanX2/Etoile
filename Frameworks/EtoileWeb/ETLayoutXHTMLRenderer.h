/**	<title>ETLayoutToXHTMLRenderer</title>

	<abstract>Transform class to export any layout to XHTML</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <EtoileWeb/ETXHTMLRenderContext.h>


@interface ETLayoutXHTMLRenderer : ETXHTMLRendering
{

}

/* Table & Outline Layout */

- (void) renderTableRowWithItem: (ETLayoutItem *)anItem;
- (void) renderTableColumnWithItem: (ETLayoutItem *)anItem;
- (void) renderTableWithItem: (ETLayoutItem *)anItem;
- (void) renderOutlineWithItem: (ETLayoutItem *)anItem;

/* Line Layout */

- (void) renderLineWithItem: (ETLayoutItem *)anItem;

/* ColumnLayout */

- (void) renderColumnWithItem: (ETLayoutItem *)anItem;

@end


/* 
@protocol ETWritingRenderer <ETRendering>
+ (id) rendererWithWriter: (id)aWriter;
@end

ETXHTMLRenderer

+ rendererWithWriter

	ETLayoutXHTMLRenderer
	ETStyleXHTMLRenderer
	ETActionHandlerRenderer

ETSVGRenderer
	
	ETLayoutSVGRenderer
	ETStyleSVGRenderer
	

ETXHTMLExporter -> LayoutXHTMLGenerator ETLayoutXHTMLGenerator ETItemXHTMLGenerator

ETXHTMLRenderer ETXHTMLDocument ETCompoundDocument
-layoutItemRepresentation
-compoundDocumentRepresentation

ETXHTMLExporter

+ writeXHTMLToURL:
+ XHTMLStringWithItem: (ETUIItem *)anItem


ETXHTMLExporter

layoutGenerator = 

XHTMLImporter -> LayoutXHTMLParser

SVGOuputRenderer SGVBuilder SVGRenderer ETStyleSVGBuilder ETStyleSVGRenderer

@interface ETXHTMLOuputRenderer : ETTransform <ETWritingRenderer>

ETLayoutXHTMLRenderer alloc initWithWriter: */
