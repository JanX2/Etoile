//
//  Method.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DocMethod.h"
#import "HtmlElement.h"
#import "DescriptionParser.h"
#import "Parameter.h"

@implementation DocMethod

- (id) init
{
	SUPERINIT;
	selectorKeywords = [NSMutableArray new];
	ASSIGN(category, @"");
	return self;
}

- (void) dealloc
{
	[selectorKeywords release];
	DESTROY(category);
	[super dealloc];
}

- (NSString *) signature
{
	NSMutableString *signature = [NSMutableString string];
	
	FOREACH(selectorKeywords, keyword, NSString *)
	{
    	[signature appendString: keyword];
	}
	return signature;
}

- (void) setIsClassMethod: (BOOL)isTrue
{
	isClassMethod = isTrue;
}

- (BOOL) isClassMethod
{
	return isClassMethod;
}

- (void) appendSelectorKeyword: (NSString *)aSelector
{
	[selectorKeywords addObject: aSelector];
}

- (void) setCategory: (NSString *)aCategory
{
	ASSIGN(category, aCategory);
}

/*
 <dl>
 <dt>+ (void) <strong>willVerify:</strong> (Class)aClass;</dt>
 <dd>
 
 This method will instantiate the contract and apply it
 on a class (i.e. through methods interception)
 
 </dd>
 </dl>
*/ 
- (HtmlElement *) HTMLDescription
{
  H h_signature = [DIV class: @"methodSignature"];
  
  if (isClassMethod) 
  {
    [h_signature with: [DIV class: @"methodScope" with: @"+"]];
  } 
  else
  {
    [h_signature with: [DIV class: @"methodScope" with: @"-"]];
  }
  
  H h_returnType = [DIV class: @"returnType" with: @"("
                          and: [DIV class: @"type" with: returnType] and: @")"];
  
  [h_signature and: h_returnType];
  
  for (int i=0; i<[selectorKeywords count]; i++)
  {
    H h_selector = [DIV class: @"selector" with: [selectorKeywords objectAtIndex: i]];
    [h_signature and: h_selector];
    if (i<[parameters count])
    {
      Parameter* p = [parameters objectAtIndex: i];
      H h_parameter = [DIV class: @"parameter" with: 
                            [NSString stringWithFormat: @"(%@) ", [p type]] 
                             //and: [DIV class: @"type" with: [p objectForKey: @"type"]] and: @") "
                             and: [DIV class: @"arg" with: [p name]]];
//      H h_parameter = [DIV class: @"parameter" with: [NSString stringWithFormat: @"(%@)", [p objectForKey: @"type"]] 
//                             and: [DIV class: @"type" with: [p objectForKey: @"type"]] and: @") "
//                             and: [DIV class: @"arg" with: [p objectForKey: @"name"]]];
      [h_signature and: h_parameter];
    }
  }

  H methodFull = [DIV class: @"method" with: 
                  [DL with: [DT with: h_signature]
                       and: [DD with: [DIV class: @"methodDescription" with: filteredDescription]]]];
  return methodFull;
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict
{
	if ([elementName isEqualToString: @"method"]) /* Opening tag */
	{
		BEGINLOG();

		[self setReturnType: [attributeDict objectForKey: @"type"]];
		if ([[attributeDict objectForKey: @"factory"] isEqualToString: @"yes"]) 
		{
			[self setIsClassMethod: YES];
		}
	}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	if ([elementName isEqualToString: @"sel"]) 
	{
		[self appendSelectorKeyword: trimmed];
	}
	else if ([elementName isEqualToString: @"arg"]) 
	{
		[self addParameter: trimmed 
		            ofType: [parser argTypeFromArgsAttributes: [parser currentAttributes]]];
	}
	else if ([elementName isEqualToString: @"desc"]) 
	{
		[self appendToRawDescription: trimmed];
		CONTENTLOG();
	}
	else if ([elementName isEqualToString: @"method"]) /* Closing tag */
	{
		DescriptionParser *descParser = AUTORELEASE([DescriptionParser new]);

		[descParser parse: [self rawDescription]];
		[self addInformationFrom: descParser];

		if ([self isClassMethod])
		{
			[parser addClassMethod: self];
		}
		else
		{
			[parser addInstanceMethod: self];
		}
		/* Cache the signature as our name and allows inherited methods that use 
		   -name to work transparently */
		[self setName: [self signature]];

		ENDLOG2([self name], [self task]);
	}
}

@end
