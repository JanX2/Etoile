//
//  Header.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DocHeader.h"
#import "DocIndex.h"
#import "HtmlElement.h"

@implementation DocHeader

@synthesize protocolName, categoryName, adoptedProtocolNames, group;

- (id) init
{
	SUPERINIT;
	authors = [NSMutableArray new];
	adoptedProtocolNames = [NSMutableArray new];
	ASSIGN(group, @"Default");
	return self;
}

- (void) dealloc
{
	[authors release];
	[className release];
	[protocolName release];
	[categoryName release];
	[superClassName release];
	[adoptedProtocolNames release];
	[abstract release];
	[overview release];
	[title release];
	[group release];
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)aZone
{
	DocHeader *copy = [super copyWithZone: aZone];

	copy->authors = [authors mutableCopyWithZone: aZone];

	/* We are not interested in copying the properties that would need to be  
	   reset to nil. e.g. when weaving a new page per class and the classes 
	   belongs to a single gsdoc file.

	ASSIGN(copy->className, className);
	ASSIGN(copy->protocolName, protocolName);
	ASSIGN(copy->categoryName, categoryName);
	ASSIGN(copy->superClassName, superClassName);
	copy->adoptedProtocolNames = [adoptedProtocolNames mutableCopyWithZone: aZone];*/

	copy->adoptedProtocolNames = [[NSMutableArray alloc] init];
	ASSIGN(copy->abstract, abstract);
	ASSIGN(copy->overview, overview);
	ASSIGN(copy->title, title);
	ASSIGN(copy->group, group);

	return copy;
}

- (NSString *) name
{
	if ([super name] != nil)
	{
		return [[[super name] componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] 
			componentsJoinedByString: @""];
	}
	/* Insert either class, category or protocol as main symbol */
	if (className != nil && categoryName == nil)
	{
		ETAssert(protocolName == nil);
		return className;
	}
	if (categoryName != nil)
	{
		ETAssert(protocolName == nil);
		return [NSString stringWithFormat: @"%@+%@", className, categoryName];
	}
	if (protocolName != nil)
	{
		return [NSString stringWithFormat: @"_%@", protocolName];	
	}

	return nil;
}

- (void) setDeclaredIn: (NSString *)aFile
{
	ASSIGN(declared, aFile);
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
			title, className];
}

- (void) setClassName: (NSString *)aName
{
	ASSIGN(className, aName);
}

- (NSString *) className
{
	return className;
}

- (void) setSuperClassName: (NSString *)aName 
{
	ASSIGN(superClassName, aName);
}

- (NSArray *) adoptedProtocolNames
{
	return AUTORELEASE([adoptedProtocolNames copy]);
}

- (void) addAdoptedProtocolName: (NSString *)aName
{
	[adoptedProtocolNames addObject: aName];
}

- (void) setAbstract: (NSString *)aDescription
{
	ASSIGN(abstract, aDescription);
}

- (void) setOverview: (NSString *)aDescription
{
	NSString *validDesc = aDescription;

	if ([aDescription isEqual: [[self class] forthcomingDescription]])
	{
		validDesc = nil;
	}

	ASSIGN(overview, validDesc);
	// FIXME: redundancy
	[self setFilteredDescription: aDescription];
}

- (void) setFileOverview: (NSString *)aFile
{
	ASSIGN(fileOverview, aFile);
}

- (void) addAuthor: (NSString *)aName
{
	if (aName != nil)
		[authors addObject: aName];
}

- (void) setTitle: (NSString *)aTitle
{
	ASSIGN(title, aTitle);
}

- (NSString *) title
{
	return title;
}

- (HtmlElement *) HTMLOverviewRepresentation
{
	H hOverview = [DIV id: @"overview" with: [H3 with: @"Overview"]];
	BOOL noOverview = (fileOverview == nil && overview == nil);

	if (noOverview)
		return [HtmlElement blankElement];

	if (fileOverview != nil)
	{
		NSString *fo = [NSString stringWithContentsOfFile: fileOverview 
		                                         encoding: NSUTF8StringEncoding 
		                                            error: NULL];
		[hOverview and: fo];
	}
	else if (overview != nil)
	{
		[hOverview and: [P with: [self HTMLDescriptionWithDocIndex: [DocIndex currentIndex]]]];
	}

	return hOverview;
}

- (HtmlElement *) HTMLRepresentation
{
	DocIndex *docIndex = [DocIndex currentIndex];
	H h_title = [DIV id: @"classname"];
	if (title)
	{
		[h_title with: [H2 with: title]];
	}

	/* Insert either class, category or protocol as main symbol */
	if (className != nil && categoryName == nil)
	{
		ETAssert(protocolName == nil);
		[h_title with: className and: @" : " and: [docIndex linkForClassName: superClassName]];
	}
	if (categoryName != nil)
	{
		ETAssert(protocolName == nil);
		[h_title with: [docIndex linkForClassName: className] 
		          and: @" (" and: categoryName and: @")"];
	}
	if (protocolName != nil)
	{
		[h_title with: protocolName];	
	}

	/* Insert adopted protocols */
	if ([adoptedProtocolNames isEmpty] == NO)
	{
		BOOL isFirstProtocol = YES;
		
		[h_title addText: @" &lt;"];
		
		for (NSString *adoptedProtocol in adoptedProtocolNames)
		{
			if (isFirstProtocol == NO)
				[h_title addText: @", "];
			
			[h_title addText: [docIndex linkForProtocolName: adoptedProtocol]];
			isFirstProtocol = NO;
		}
		[h_title addText: @"&gt;"];
	}

	/* Build authors and declared in table */
	H table = TABLE;
	H tdAuthors = TD;

	for (NSString *author in authors)
	{
		[tdAuthors with: author and: @" "];
	}
	if ([authors isEmpty] == NO)
	{
		[table add: [TR with: [TH with: @"Authors"] and: tdAuthors]];
	}
	if (declared != nil)
	{
		[table add: [TR with: [TH with: @"Declared in:"] and: [TD with: declared]]];
	}

	// TODO: Could be better not to insert an empty table when authors is empty and declared is nil
	H meta = [DIV id: @"meta" with: [P id: @"metadesc" with: abstract] and: table];

	/* Pack title, meta and overview in a header html element */
	H header = [DIV id: @"header" with: h_title and: meta and: [self HTMLOverviewRepresentation]];

	return header;
}

// TODO: Use correct span class names...
- (HtmlElement *) HTMLTOCRepresentation
{
	DocIndex *docIndex = [DocIndex currentIndex];
	H hEntryName = [SPAN class: @"symbolName"];

	/* Insert either class, category or protocol as main symbol */
	if (className != nil && categoryName == nil)
	{
		ETAssert(protocolName == nil);
		[hEntryName with: className and: @" : " and: [docIndex linkForClassName: superClassName]];
	}
	if (categoryName != nil)
	{
		ETAssert(protocolName == nil);
		[hEntryName with: [docIndex linkForClassName: className] 
		             and: @" (" and: categoryName and: @")"];
	}
	if (protocolName != nil)
	{
		[hEntryName with: protocolName];	
	}

	NSString *description = [self HTMLDescriptionWithDocIndex: [DocIndex currentIndex]];
	H hEntryDesc = [DIV class: @"symbolDescription" with: [P with: description]];

	return [DIV class: @"symbol" with: [DL with: [DT with: hEntryName]
                                            and: [DD with: hEntryDesc]]];
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict
{
	if ([elementName isEqualToString: @"head"]) /* Opening tag */
	{
		BEGINLOG();
	}
	else if ([elementName isEqualToString: @"author"]) 
	{
		[self addAuthor: [attributeDict objectForKey: @"name"]];
	}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	if ([elementName isEqualToString: @"abstract"])
	{
		[self setAbstract: trimmed];
		CONTENTLOG();
	}
	else if ([elementName isEqualToString: @"title"]) 
	{ 
		[self setTitle: trimmed];
	}
	else if ([elementName isEqualToString: @"head"]) /* Closing tag */
	{
		[[parser weaver] weaveHeader: self];

		ENDLOG2(title, className);
	}
}

@end
