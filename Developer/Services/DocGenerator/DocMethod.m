/*
	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import "DocMethod.h"
#import "DocIndex.h"
#import "DocHTMLElement.h"
#import "DocDescriptionParser.h"
#import "DocParameter.h"

@implementation DocMethod

- (id) init
{
	SUPERINIT;
	selectorKeywords = [NSMutableArray new];
	return self;
}

- (void) dealloc
{
	DESTROY(selectorKeywords);
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

- (NSString *) refMarkup
{
	char sign = (isClassMethod ? '+' : '-');
	return [NSString stringWithFormat: @"%c%@", sign, [self name]];
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

- (DocHTMLElement *) HTMLAnchorRepresentation
{
	/* -ownerSymbolName can return either a class or protocol e.g. ClassName or 
	   (ProtocolName), so -refMarkupWithClassName: with the latter would return 
	   a protocol ref markup. */
	NSString *linkId = [self refMarkupWithClassName: [self ownerSymbolName]];
	return [A name: [linkId stringByReplacingOccurrencesOfString: @" " withString: @"_"]];
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
- (DocHTMLElement *) HTMLRepresentation
{
	DocHTMLIndex *docIndex = [DocIndex currentIndex];

	H hReturn = [[self returnParameter] HTMLRepresentationWithParentheses: YES];
	H hReturnType = [SPAN class: @"returnType" 
	                       with: [SPAN class: @"type" with: hReturn]];
	H hSignature = [SPAN class: @"methodSignature" 
	                      with: [SPAN class: @"methodScope" 
	                                   with: (isClassMethod ? @"+ " : @"- ")]	
	                       and: hReturnType];

	NSArray *params = [self parameters];
	BOOL isUnaryMessage = [params isEmpty];

	for (int i = 0; i < [selectorKeywords count]; i++)
	{
		NSString *selKeyword = [selectorKeywords objectAtIndex: i];
		H hSelector = [SPAN class: @"selector" with: @" " and: selKeyword and: @" "];

		[hSignature and: hSelector];

		if (isUnaryMessage)
			break;

		DocParameter *p = [params objectAtIndex: i];
	
		[hSignature and: [p HTMLRepresentationWithParentheses: YES]];
	}

	// FIXME: HTML output below broken
	/*H hAnchoredSig = [[self HTMLAnchorRepresentation] with: hSignature];
	H hMethodDesc = [DIV class: @"methodDescription" 
	                      with: [self HTMLDescriptionWithDocIndex: docIndex]];
	H hMethodDiv = [DIV class: @"method" with: [DL with: [DT with: hAnchoredSig]
	                                                and: [DD with: hMethodDesc]]];*/
	H hMethodDesc = [DIV class: @"methodDescription" 
	                      with: [self HTMLDescriptionWithDocIndex: docIndex]
	                       and: [self HTMLAddendumRepresentation]];
	H hMethodBlock = [DIV class: @"method" with: [self HTMLAnchorRepresentation]
	                                        and: [DL class: @"collapsable" with: [DT with: hSignature]
	                                                                        and: [DD with: hMethodDesc]]];

	//NSLog(@"Method %@", hMethodBlock);
	return hMethodBlock;
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
		NSString *type = [parser argTypeFromArgsAttributes: [parser currentAttributes]];
		[self addParameter: [DocParameter parameterWithName: trimmed type: type]];
	}
	else if ([elementName isEqualToString: @"desc"]) 
	{
		[self appendToRawDescription: trimmed];
		CONTENTLOG();
	}
	else if ([elementName isEqualToString: @"method"]) /* Closing tag */
	{
		DocDescriptionParser *descParser = AUTORELEASE([DocDescriptionParser new]);

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
