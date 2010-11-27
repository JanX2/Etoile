//
//  Header.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DocHeader.h"
#import "HtmlElement.h"

@implementation DocHeader

@synthesize protocolName, categoryName, adoptedProtocolNames;

- (id) init
{
	SUPERINIT;
	authors = [NSMutableArray new];
	adoptedProtocolNames = [NSMutableArray new];
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
	[super dealloc];
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
	ASSIGN(overview, aDescription);
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

- (HtmlElement *) HTMLDescription
{
	H h_title = [DIV id: @"classname"];
	if (title)
	{
		[h_title with: [H2 with: title]];
	}

	/* Insert either class, category or protocol as main symbol */
	if (className != nil && categoryName == nil)
	{
		ETAssert(protocolName == nil);
		[h_title with: className and: @" : " and: superClassName];
	}
	if (categoryName != nil)
	{
		ETAssert(protocolName == nil);
		[h_title with: className and: @" (" and: categoryName and: @")"];
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
			
			[h_title addText: adoptedProtocol];
			isFirstProtocol = NO;
		}
		[h_title addText: @"&gt;"];
	}
	
	H tdAuthors = TD;
	for (NSString *author in authors)
	{
		[tdAuthors with: author and: @" "];
	}
	H table = [TABLE with: [TR with: [TH with: @"Authors"] and: tdAuthors]
					  and: [TR with: [TH with: @"Declared in:"] and: [TD with: declared]]];
	H meta = [DIV id: @"meta" with: [P id: @"metadesc" with: abstract] and: table];
	H h_overview = [DIV id: @"overview" with: [H3 with: @"Overview"]];
	BOOL setOverview = NO;

	/* Insert Overview */
	if (fileOverview != nil)
	{
		NSString *fo = [NSString stringWithContentsOfFile: fileOverview encoding: NSUTF8StringEncoding error: NULL];
		[h_overview and: fo];
		setOverview = YES;
	}
	else if (overview != nil)
	{
		[h_overview and: [P with: overview]];
		setOverview = YES;
	}

	/* Pack title, meta and overview in a header html element */
	H header = [DIV id: @"header" with: h_title and: meta];
	if (setOverview) 
	{
		[header and: h_overview];
	}

	return header;
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
