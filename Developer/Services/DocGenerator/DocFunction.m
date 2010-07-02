//
//  Function.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DocFunction.h"
#import "HtmlElement.h"
#import "DescriptionParser.h"
#import "Parameter.h"

@implementation DocFunction

- (id) init
{
	SUPERINIT;
	parameters = [NSMutableArray new];
	task = [[NSString alloc] initWithString: @"Default"];
	return self;
}

- (void) dealloc
{
	[parameters release];
	[task release];
	[returnDescription release];
	[task release];
	[returnType release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
			name, [self task]];
}

- (NSComparisonResult) caseInsensitiveCompare: (NSString *)aString
{
	return [aString caseInsensitiveCompare: name];
}

- (NSString *) task
{
	return task;
}

- (void) setTask: (NSString *)aTask
{
	ASSIGN(task, aTask);
}

- (void) setReturnType: (NSString *) aReturnType
{
	ASSIGN(returnType, aReturnType);
}

- (void) setReturnDescription: (NSString *)aDescription
{
	ASSIGN(returnDescription, aDescription);
}

- (void) addParameter: (NSString *)aName ofType: (NSString *)aType
{
	//  [parameters addObject: [NSDictionary dictionaryWithObjectsAndKeys: aName, @"name", aType, @"type", nil]];
	[parameters addObject: [Parameter newWithName: aName andType: aType]];
}

- (void) setDescription: (NSString *)aDescription forParameter: (NSString *)aName
{
	FOREACH(parameters, p, Parameter *)
	{
		if ([[p name] isEqualToString: aName])
		{
			[p setDescription: aDescription];
			return;
		}
	}
}

- (void) addInformationFrom: (DescriptionParser *)aParser
{
	[super addInformationFrom: aParser];
	
	FOREACH(parameters, p, Parameter *)
	{
		[p setDescription: [aParser descriptionForParameter: [p name]]];
	}    
	//NSLog (@"Parser return description <%@>", [aParser returnDescription]);
	[self setReturnDescription: [aParser returnDescription]]; 
	[self setTask: [aParser task]];
}

- (H) richDescription
{
	H param_list = [DIV class: @"paramsList"];
	H ul = UL;

	if ([parameters count] > 0)
	{
		[param_list and: [H3 with: @"Parameters"]];
	}

	FOREACH(parameters, p, Parameter *)
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
	
	[param_list and: [H3 with: @"Description"]];
	[param_list and: filteredDescription];

	return param_list;
}

- (NSString *) content
{
	H h_signature = [DIV class: @"methodSignature"];
	H h_returnType = [DIV class: @"returnType" with: [DIV class: @"type" with: returnType]];
	
	[h_signature and: h_returnType];
	
	[h_signature and: [DIV class: @"selector" with: name]];
	[h_signature with: @"("];

	BOOL isFirst = YES;
	FOREACH(parameters, p, Parameter *)
	{
		H h_parameter = [DIV class: @"parameter" with: 
		                [DIV class: @"type" with: [p type]] 
		                       and: @" " and: [DIV class: @"arg" with: [p name]]];
		if (NO == isFirst)
		{
			[h_signature and: @","];
		}
		[h_signature and: h_parameter];

		isFirst = NO;
	}
	[h_signature with: @")"];
	
	H methodFull = [DIV class: @"method" with: 
	                 [DL with: [DT with: h_signature]
	                      and: [DD with: [DIV class: @"methodDescription" with: [self richDescription]]]]];
	return [methodFull content];
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
 withAttributes: (NSDictionary *)attributeDict
{
	if ([elementName isEqualToString: @"function"]) /* Opening tag */
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
		[self addParameter: trimmed
		            ofType: [parser argTypeFromArgsAttributes: [parser currentAttributes]]];	
	}
	else if ([elementName isEqualToString: @"desc"]) 
	{
		[self appendToRawDescription: trimmed];
		CONTENTLOG();
	}
	else if ([elementName isEqualToString: @"function"]) /* Closing tag */
	{
		DescriptionParser* descParser = [DescriptionParser new];
		
		[descParser parse: [self rawDescription]];
		
		//NSLog(@"Function raw description <%@>", [self rawDescription]);
		
		[self addInformationFrom: descParser];
		[descParser release];
		
		[parser addFunction: self];
		
		ENDLOG2(name, [self task]);
	}
}

@end
