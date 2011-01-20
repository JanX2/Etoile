/*
	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import "DocFunction.h"
#import "DocHTMLElement.h"
#import "DocDescriptionParser.h"
#import "DocIndex.h"
#import "DocParameter.h"

@implementation DocFunction

- (void) dealloc
{
	[returnDescription release];
	[super dealloc];
}

- (void) setReturnDescription: (NSString *)aDescription
{
	ASSIGN(returnDescription, aDescription);
}

- (void) setDescription: (NSString *)aDescription forParameter: (NSString *)aName
{
	FOREACH([self parameters], p, DocParameter *)
	{
		if ([[p name] isEqualToString: aName])
		{
			[p setDescription: aDescription];
			return;
		}
	}
}

- (H) HTMLAddendumRepresentation
{
	H param_list = [DIV class: @"paramsList"];
	H ul = UL;

	if ([[self parameters] count] > 0)
	{
		[param_list and: [H3 with: @"Parameters"]];
	}

	FOREACH([self parameters], p, DocParameter *)
	{
		H h_param = [LI with: [I with: [p name]]];
		[h_param and: [p description]];
		[ul and: h_param];
	}
	[param_list and: ul];
	
	if ([returnDescription length])
	{
		[param_list and: [H3 with: @"Return"]];
		[param_list and: returnDescription];
	}

	return param_list;
}

- (DocHTMLElement *) HTMLRepresentation
{
	H h_signature = [SPAN class: @"methodSignature"];
	H h_returnType = [SPAN class: @"returnType" 
	                       with: [SPAN class: @"type" with: [[self returnParameter] HTMLRepresentationWithParentheses: NO]]];
	
	[h_signature and: h_returnType];
	[h_signature and: [SPAN class: @"selector" with: @" " and: [self name]]];
	[h_signature with: @"("];

	BOOL isFirst = YES;
	FOREACH([self parameters], p, DocParameter *)
	{
		H h_parameter = [p HTMLRepresentationWithParentheses: NO];

		if (NO == isFirst)
		{
			[h_signature and: @", "];
		}
		[h_signature and: h_parameter];

		isFirst = NO;
	}
	[h_signature with: @")"];

	H hMethodDesc = [DIV class: @"methodDescription" 
		                  with: [self HTMLDescriptionWithDocIndex: [DocIndex currentIndex]]
	                       and: [self HTMLAddendumRepresentation]];
	H methodFull = [DIV class: @"method" 
	                     with: [DL with: [DT with: h_signature]
	                                and: [DD with: hMethodDesc]]];

	return methodFull;
}

- (NSString *) GSDocElementName
{
	return @"function";
}

- (SEL) weaveSelector
{
	return @selector(weaveFunction:);
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
 withAttributes: (NSDictionary *)attributeDict
{
	if ([elementName isEqualToString: [self GSDocElementName]]) /* Opening tag */
	{
		BEGINLOG();
		[self setReturnType: [attributeDict objectForKey: @"type"]];
		[self setName: [attributeDict objectForKey: @"name"]];
	}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	if ([elementName isEqualToString: @"arg"]) 
	{
		NSString *type = [parser argTypeFromArgsAttributes: [parser currentAttributes]];
		[self addParameter: [DocParameter parameterWithName: trimmed type: type]];	
	}
	else if ([elementName isEqualToString: @"desc"]) 
	{
		[self appendToRawDescription: trimmed];
		CONTENTLOG();
	}
	else if ([elementName isEqualToString: [self GSDocElementName]]) /* Closing tag */
	{
		DocDescriptionParser* descParser = [DocDescriptionParser new];

				if ([[self name] hasPrefix: @"generateClassMapping"])
				{
					NSLog(@"bla");
				}
		[descParser parse: [self rawDescription]];
		
		//NSLog(@"Function raw description <%@>", [self rawDescription]);
		
		[self addInformationFrom: descParser];
		[descParser release];
		
		[(id)[parser weaver] performSelector: [self weaveSelector] withObject: self];
		
		ENDLOG2(name, [self task]);
	}
}



@end
