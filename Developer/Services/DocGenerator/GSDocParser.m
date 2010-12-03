//
//  GSDocParser.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GSDocParser.h"
#import "DocConstant.h"
#import "DocHeader.h"
#import "DocMethod.h"
#import "DocFunction.h"
#import "HtmlElement.h"
#import "DescriptionParser.h"

@interface NullParserDelegate : NSObject <GSDocParserDelegate>
@end


@implementation GSDocParser

- (id) init
{
	return [self initWithString: nil];
}

- (id) initWithString: (NSString *)aContent
{
	NSParameterAssert(aContent != nil);
	SUPERINIT;

	xmlParser = [[NSXMLParser alloc] initWithData: 
    	[aContent dataUsingEncoding: NSUTF8StringEncoding]];
	[xmlParser setDelegate: self];
	parserDelegateStack = [[NSMutableArray alloc] initWithObjects: [NSValue valueWithNonretainedObject: self], nil];
	indentSpaces = @"";
	indentSpaceUnit = @"  ";
	elementClasses = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
		[DocHeader class], @"head", 
		[NullParserDelegate class], @"ivariable",
		[DocMethod class], @"method",
		[DocFunction class], @"function",
		[DocConstant class], @"constant", nil];
	// NOTE: ref elements are pruned. DocIndex is used instead.
	substitutionElements = [[NSDictionary alloc] initWithObjectsAndKeys: @"list", @"ul", 
		@"item", @"li", @"enum", @"ol", @"deflist", @"dl", @"term", @"dt", @"desc", @"dd", @"", @"ref", nil];
	// NOTE: var corresponds to GSDoc var and not HTML var
	etdocElements = [[NSSet alloc] initWithObjects: @"p", @"code", @"example", @"br", @"em", @"strong", @"var", @"ivar", nil]; 

	content = [NSMutableString new];
	
	return self;
}

- (void) dealloc
{
	[xmlParser release];
	[parserDelegateStack release];
	[elementClasses release];
    [substitutionElements release];
	[etdocElements release];
	[content release];
	[super dealloc];
}

- (void) setWeaver: (id <CodeDocWeaving>)aDocWeaver
{
	/* The weaver retains the parser */
	weaver = aDocWeaver;
}

- (id <CodeDocWeaving>) weaver
{
	return weaver;
}

- (void) parseAndWeave
{
	[xmlParser parse];
}

- (void) newContent
{
	[content release];
	content = [NSMutableString new];
}

- (Class) elementClassForName: (NSString *)anElementName
{
	return [elementClasses objectForKey: anElementName];
}

- (id <GSDocParserDelegate>) parserDelegate
{
	id parserDelegate = [parserDelegateStack lastObject];
    BOOL isWeakRef = [parserDelegate isKindOfClass: [NSValue class]];
    return (isWeakRef ? [parserDelegate nonretainedObjectValue] : parserDelegate);
}

- (void) increaseIndentSpaces
{
	ASSIGN(indentSpaces, [indentSpaces stringByAppendingString: indentSpaceUnit]);
}

- (void) decreaseIndentSpaces
{
	NSUInteger i = [indentSpaces length] - [indentSpaceUnit length];
	ETAssert(i >= 0);
	ASSIGN(indentSpaces, [indentSpaces substringToIndex: i]);
}

- (void) pushParserDelegate: (id <GSDocParserDelegate>)aDelegate
{
	if ([parserDelegateStack lastObject] != aDelegate)
	{
		[self increaseIndentSpaces];
	}
	[parserDelegateStack addObject: aDelegate];
}

- (void) popParserDelegate
{
	id objectBeforeLast = [parserDelegateStack objectAtIndex: [parserDelegateStack count] - 2];

	if ([parserDelegateStack lastObject] != objectBeforeLast)
	{
		[self decreaseIndentSpaces];
	}
	[parserDelegateStack removeObjectAtIndex: [parserDelegateStack count] - 1];
}

- (NSString *) indentSpaces
{
	return indentSpaces;
}

- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
     attributes:(NSDictionary *)attributeDict
{
	NSLog (@"%@  parse <%@>", indentSpaces, elementName);

	NSString *substituedElement = [substitutionElements objectForKey: elementName];
	BOOL removeMarkup = [substituedElement isEqualToString: @""];
	BOOL substituteMarkup = (substituedElement != nil && removeMarkup == NO);
	BOOL keepMarkup = [etdocElements containsObject: elementName];

	/* (1) For GSDoc tags which have equivalent ETDoc tags, we insert their content 
	   enclosed in equivalent ETDoc tags into our content accumulator. 
	   The next handled element can retrieve the accumulated content. For example:
	   <desc><i>A boat</i> on <j>the</j> river.</desc>
	   if i and j are GSDoc elements equivalent to x and y in ETDoc, the 
	   accumulated content will be:
	   <desc><x>A boat</x> on <y>the</y> river.</desc>

 	   (2) For ETDoc tags, we insert them along with their content in our content accumulator. 
	   The next handled element can retrieve the accumulated content. For example:
	   <desc><i>A boat<i> on <j>the</j> river.</desc>
	   if i and j are ETDoc elements, the accumulated content will be:
	   <i>A boat</i>on <j>the</j> river. */
	if (removeMarkup)
	{
		return;
	}
	else if (substituteMarkup)
	{
		[content appendString: [NSString stringWithFormat: @"<%@>", substituedElement]];
		return;
	}
	else if (keepMarkup)
	{
		[content appendString: [NSString stringWithFormat: @"<%@>", elementName]];
		return;
	}

	ASSIGN(currentAttributes, attributeDict);

	id parserDelegate = [self parserDelegate];

	/* When we have a parser delegate registered for the new element name, 
	   we switch this delegate, otherwise we continue with the current one. */
	if ([self elementClassForName: elementName] != nil)
	{
		parserDelegate = AUTORELEASE([[self elementClassForName: elementName] new]);
	}
	[self pushParserDelegate: parserDelegate];

	NSLog(@"%@  Begin <%@>, parser %@", indentSpaces, elementName, [(id)[self parserDelegate] primitiveDescription]);
	[[self parserDelegate] parser: self startElement: elementName withAttributes: attributeDict];
}

- (void) parser: (NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	[content appendString: string];
}

- (void) parser: (NSXMLParser *)parser
  didEndElement: (NSString *)elementName
   namespaceURI: (NSString *)namespaceURI
  qualifiedName: (NSString *)qName
{
	NSString* trimmed = [content stringByTrimmingCharactersInSet: 
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString *substituedElement = [substitutionElements objectForKey: elementName];
	BOOL removeMarkup = [substituedElement isEqualToString: @""];
	BOOL substituteMarkup = (substituedElement != nil && removeMarkup == NO);
	BOOL keepMarkup = [etdocElements containsObject: elementName];

	/* See comment in -parser:didStartElement:namespaceURI:qualifiedName: */
	if (removeMarkup)
	{
		return;
	}
	else if (substituteMarkup)
	{
		[content appendString: [NSString stringWithFormat: @"</%@>", substituedElement]];
		return;
	}
	else if (keepMarkup)
	{
		[content appendString: [NSString stringWithFormat: @"</%@>", elementName]];
		return;
	}

	[[self parserDelegate] parser: self endElement: elementName withContent: trimmed];
	NSLog(@"%@  End <%@> --> %@", indentSpaces, elementName, trimmed);

	[self popParserDelegate];
	/* Discard the content accumulated to handle the element which ends. */
	[self newContent];
	DESTROY(currentAttributes);
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict
{
	/* The main parser is responsible to parse the class attributes */
	if ([elementName isEqualToString: @"class"]) 
	{
        	[weaver weaveClassNamed: [attributeDict objectForKey: @"name"]
		         superclassName: [attributeDict objectForKey: @"super"]];
	}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	/* When we parse a class, we parse the declared child element too */
	if ([elementName isEqualToString: @"declared"])
	{
		ETAssert(nil != [weaver currentHeader]);
		[[weaver currentHeader] setDeclaredIn: trimmed];
	}
	else if ([elementName isEqualToString: @"conform"])
	{
		ETAssert(nil != [weaver currentHeader]);
		[[weaver currentHeader] addAdoptedProtocolName: trimmed];
	}
	else if ([elementName isEqualToString: @"desc"])
	{
		ETAssert(nil != [weaver currentHeader]);
		[[weaver currentHeader] setOverview: trimmed];
	}
}

- (NSDictionary *) currentAttributes
{
	NSParameterAssert(nil != currentAttributes);
	return currentAttributes;
}

- (NSString *) argTypeFromArgsAttributes: (NSDictionary *)attributeDict
{
	NSString *argType = [attributeDict objectForKey: @"type"];
	ETAssert(nil != argType);
	return [argType stringByTrimmingCharactersInSet: 
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end


@implementation NullParserDelegate 

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict
{

}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{

}

@end
