/**
	<abstract>Documentation page header or subheader.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocElement.h"
#import "GSDocParser.h"

@class DocHTMLElement;

/** @group Doc Element Tree */
@interface DocHeader : DocElement <GSDocParserDelegate>
{
	/* Basic Infos */
	NSString *title;
	NSString *abstract;
	NSMutableArray *authors;
	NSString *overview;
	NSString *fileOverview;
	
	/* Main Symbol (optional) presented on the page */
	NSString *className;
	NSString *protocolName;
	NSString *categoryName;
	NSString *declaredIn;

	/* Main Symbol Inheritance (optional) */
	NSString *superclassName;
	NSMutableArray *adoptedProtocolNames;

	/* Parsed Markup */
	NSString *group;

}

/** @taskunit Basic Infos */

/** Adds the given author name to the author list. */
- (void) addAuthor: (NSString *)aName;
/** The page title.

See also -[DocElement name] which is a distinct property. */
@property (retain, nonatomic) NSString *title;
/** A brief summary limited to single line. */
@property (retain, nonatomic) NSString *abstract;
/** The main documentation.

In most cases, the overview describes a class, a category or a protocol that 
the header introduces. And as such corresponds to the class, category or 
protocol description comment in the code source.

See also -setFileOverview:. */
@property (retain, nonatomic) NSString *overview;
/** An additional documentation appended to -overview when the final output is 
generated.

You should use -setFileOverview: rather than -setOverview:, when the overview 
is stored outside the code. e.g. in a Markdown file. */
@property (retain, nonatomic) NSString *fileOverview;
/** The main authors who contributed to the code or content the header is related to. */
@property (readonly, nonatomic) NSArray *authors;
/** Returns the group name parsed from <em>@group</em> markup.

A header or the symbol it represents can belong to one or several groups (only one for now). */
@property (retain, nonatomic) NSString *group;

/** @taskunit Documented Class, Protocol or Category */

/** Adds a protocol name to -adoptedProtocolNames. */
- (void) addAdoptedProtocolName: (NSString *)aName;
/** The class presented on the page the header belongs to. */
@property (retain, nonatomic) NSString *className;
/** The superclass of the class presented on the page the header belongs to.

The class refers to the symbol the header introduces.<br />
See -className. */
@property (retain, nonatomic) NSString *superclassName;
/** The category presented on the page the header belongs to. */
@property (retain, nonatomic) NSString *categoryName;
/** The protocol presented on the page the header belongs to. */
@property (retain, nonatomic) NSString *protocolName;
/** The protocols to which the class, protocol or category conforms to.

The class, protocol or category refers to the symbol the header introduces.<br />
See -className, -protocolName and -categoryName. */
@property (readonly, nonatomic) NSArray *adoptedProtocolNames;
/** The name of the file in which the documented symbol is declared. 

For DocHeader class, that would be DocHeader.h. */
@property (retain, nonatomic) NSString *declaredIn;

/** @taskunit HTML Generation */

/** Returns the overview rendered as a HTML element tree.

Will return +[DocHTMLElement blankElement] if no overview is available. */
- (DocHTMLElement *) HTMLOverviewRepresentation;
/** Returns the entire header rendered as a HTML element tree.

The returned representation includes -HTMLOverviewRepresentation.

The method creates a title block and hands it to 
-HTMLRepresentationWithTitleBlockElement: in order to obtain the HTML 
representation that should be returned. */
- (DocHTMLElement *) HTMLRepresentation;
/** Returns the entire header rendered as a HTML element tree with a custom 
title element at the beginning.

The returned representation includes -HTMLOverviewRepresentation. */
- (DocHTMLElement *) HTMLRepresentationWithTitleBlockElement: (DocHTMLElement *)hTitleBlock;
/** Returns a short header, limited to its overview, rendered as a HTML element 
tree.

The returned representation includes -HTMLOverviewRepresentation.

See DocTOCPage which uses this custom representation. e.g. to present all 
the classes, categories and protocol on the API overview page. */
- (DocHTMLElement *) HTMLTOCRepresentation;

@end
