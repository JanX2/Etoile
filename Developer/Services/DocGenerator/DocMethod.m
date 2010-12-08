//
//  Method.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DocMethod.h"
#import "DocIndex.h"
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

- (NSString *) refMarkupWithClassName: (NSString *)aClassName
{
	char sign = (isClassMethod ? '+' : '-');
	return [NSString stringWithFormat: @"%c[%@ %@]", sign, aClassName, [self name]];
}

- (NSString *) refMarkupWithProtocolName: (NSString *)aProtocolName
{
	char sign = (isClassMethod ? '+' : '-');
	return [NSString stringWithFormat: @"%c[(%@) %@]", sign, aProtocolName, [self name]];
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
- (HtmlElement *) HTMLRepresentation
{
	DocIndex *docIndex = [DocIndex currentIndex];
	H h_signature = [SPAN class: @"methodSignature"];
	
	[h_signature with: [SPAN class: @"methodScope" 
	                         with: (isClassMethod ? @"+ " : @"- ")]];
	
	H h_returnType = [SPAN class: @"returnType" 
	                       with: [SPAN class: @"type" with: [[self returnParameter] HTMLRepresentationWithParentheses: YES]]];
	
	[h_signature and: h_returnType];

	BOOL isUnaryMessage = [parameters isEmpty];

	for (int i = 0; i < [selectorKeywords count]; i++)
	{
		NSString *selKeyword = [selectorKeywords objectAtIndex: i];
		H h_selector = [SPAN class: @"selector" with: @" " and: selKeyword and: @" "];

		[h_signature and: h_selector];

		if (isUnaryMessage)
			break;

        Parameter *p = [parameters objectAtIndex: i];
    
        [h_signature and: [p HTMLRepresentationWithParentheses: YES]];
	}
	
	H methodFull = [DIV class: @"method" 
	                     with: [DL with: [DT with: h_signature]
                                    and: [DD with: [DIV class: @"methodDescription" 
	                                                     with: [self HTMLDescriptionWithDocIndex: docIndex]]]]];
	//NSLog(@"Method %@", methodFull);
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

		/* Cache the signature as our name and allows inherited methods that use 
		   -name to work transparently */
		[self setName: [self signature]];

        [[parser weaver] weaveMethod: self];

		ENDLOG2([self name], [self task]);
	}
}

@end
