//
//  Header.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocElement.h"
#import "GSDocParser.h"

@class HtmlElement;

/** @group Doc Element Tree */
@interface DocHeader : DocElement <GSDocParserDelegate>
{
	/* Main Symbol (optional) presented on the page */
	NSString *className;
	NSString *protocolName;
	NSString *categoryName;
	
	/* Main Symbol Inheritance (optional) */
	NSString *superClassName;
	NSMutableArray *adoptedProtocolNames;
	
	NSString *abstract;
	NSString *overview;
	NSString *fileOverview;
	NSMutableArray *authors;
	NSString *declared;
	NSString *title;

	/* Parsed Markup */
	NSString *group;

}

- (void) setDeclaredIn: (NSString *)aFile;
- (void) setClassName: (NSString *)aName;
- (NSString *) className;
- (void) setSuperClassName: (NSString *)aName;
/* Adds a protocol name to -adoptedProtocolNames. */
- (void) addAdoptedProtocolName: (NSString *)aName;
- (void) setAbstract: (NSString *)aDescription;
- (void) setOverview: (NSString *)aDescription;
- (void) setFileOverview: (NSString *)aFile;
- (void) addAuthor: (NSString *)aName;
- (void) setTitle: (NSString *)aTitle;
- (NSString *) title;

/** @taskunit HTML Generation */

- (HtmlElement *) HTMLOverviewRepresentation;
- (HtmlElement *) HTMLRepresentation;
- (HtmlElement *) HTMLTOCRepresentation;

/** The category presented on the page the header belongs to. */
@property (retain, nonatomic) NSString *categoryName;
/** The protocol presented on the page the header belongs to. */
@property (retain, nonatomic) NSString *protocolName;
/** The protocols to which the class, protocol or category conforms to.

The class, protocol or category refers to the symbol the header introduces.<br />
See -className, -protocolName and -categoryName. */
@property (readonly, nonatomic) NSArray *adoptedProtocolNames;
/** Returns the group name parsed from <em>@group</em> markup.

A header or the symbol it represents can belong to one or several groups (only one for now). */
@property (retain, nonatomic) NSString *group;

@end
