/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import <objc/runtime.h>
#import "DocCDataType.h"
#import "DescriptionParser.h"
#import "DocIndex.h"
#import "HtmlElement.h"

@implementation DocCDataType

@synthesize type;

- (void) dealloc
{
	DESTROY(type);
	[super dealloc];
}

- (BOOL) isConstant
{
	return ([type hasPrefix: @"enum"] || [type hasPrefix: @"union"] 
		|| [type hasPrefix: @"const"] || [type hasSuffix: @"const"]);
}

- (void) turnIntoDocConstantIfNeeded
{
	if ([self isConstant])
	{
		object_setClass(self, [DocConstant class]);
	}
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict
{
	if ([elementName isEqualToString: [self GSDocElementName]]) /* Opening tag */
	{
		BEGINLOG();
		[self setType: [attributeDict objectForKey: @"type"]];
		[self setName: [attributeDict objectForKey: @"name"]];
	}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	if ([elementName isEqualToString: @"desc"]) 
	{
		[self appendToRawDescription: trimmed];
		CONTENTLOG();
	}
	else if ([elementName isEqualToString: [self GSDocElementName]]) /* Closing tag */
	{
		DescriptionParser* descParser = [DescriptionParser new];
		
		[descParser parse: [self rawDescription]];
		
		//NSLog(@"C Data Type raw description <%@>", [self rawDescription]);
		
		[self addInformationFrom: descParser];
		[descParser release];

		/* Switch the class to get the right -weaveSelector */
		[self turnIntoDocConstantIfNeeded];
		[(id)[parser weaver] performSelector: [self weaveSelector] withObject: self];
		
		ENDLOG2(name, [self task]);
	}
}

- (NSString *) GSDocElementName
{
	return @"type";
}

- (SEL) weaveSelector
{
	return @selector(weaveOtherDataType:);
}

@end


@implementation DocConstant

- (NSString *) GSDocElementName
{
	return @"constant";
}

- (SEL) weaveSelector
{
	return @selector(weaveConstant:);
}


@end

