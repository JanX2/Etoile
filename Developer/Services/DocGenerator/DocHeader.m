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
  self = [super init];
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

- (void) setDeclaredIn: (NSString*) aFile
{
  [aFile retain];
  [declared release];
  declared = aFile;
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
	title, className];
}

- (void) setClassName: (NSString*) aName
{
  [aName retain];
  [className release];
  className = aName;
}

- (NSString *) className
{
	return className;
}

- (void) setSuperClassName: (NSString*) aName 
{
  [aName retain];
  [superClassName release];
  superClassName = aName;
}

- (NSArray *) adoptedProtocolNames
{
	return AUTORELEASE([adoptedProtocolNames copy]);
}

- (void) addAdoptedProtocolName: (NSString *)aName
{
	[adoptedProtocolNames addObject: aName];
}

- (void) setAbstract: (NSString*) aDescription
{
  [aDescription retain];
  [abstract release];
  abstract = aDescription;
}

- (void) setOverview: (NSString*) aDescription
{
  [aDescription retain];
  [overview release];
  overview = aDescription;
}

- (void) setFileOverview: (NSString*) aFile
{
  [aFile retain];
  [fileOverview release];
  fileOverview = aFile;
}

- (void) addAuthor: (NSString*) aName
{
  if (aName != nil)
    [authors addObject: aName];
}

- (void) setTitle: (NSString*) aTitle
{
  [aTitle retain];
  [title release];
  title = aTitle;
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
  for (int i=0; i<[authors count]; i++)
  {
    [tdAuthors with: [authors objectAtIndex: i] and: @" "];
  }
  H table = [TABLE with: [TR with: [TH with: @"Authors"] and: tdAuthors]
                               and: [TR with: [TH with: @"Declared in:"] and: [TD with: declared]]];
  H meta = [DIV id: @"meta" with: [P id: @"metadesc" with: abstract] and: table];
  H h_overview = [DIV id: @"overview" with: [H3 with: @"Overview"]];
  BOOL setOverview = NO;
  if (fileOverview != nil)
  {
    NSString* fo = [NSString stringWithContentsOfFile: fileOverview encoding: NSUTF8StringEncoding error: NULL];
    [h_overview and: fo];
    setOverview = YES;
  }
  else if (overview != nil)
  {
    [h_overview and: [P with: overview]];
    setOverview = YES;
  }
  H header = [DIV id: @"header" with: h_title and: meta];
  if (setOverview) [header and: h_overview];
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
