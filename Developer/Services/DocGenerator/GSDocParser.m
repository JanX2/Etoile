//
//  GSDocParser.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GSDocParser.h"
#import "Header.h";
#import "Method.h";
#import "Function.h";
#import "HtmlElement.h";
#import "DescriptionParser.h";

@implementation GSDocParser

- (id) init
{
	SUPERINIT;

	parserDelegateStack = [[NSMutableArray alloc] initWithObjects: self, nil];
	elementClasses = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
		[Header class], @"head", 
		[Method class], @"method", 
		[Function class], @"function", nil];
	// TODO: Handle them in a better way. Probably apply a style.
	transparentElements = [[NSSet alloc] initWithObjects: @"var", @"code", @"em", nil];

	content = [NSMutableString new];
	classMethods = [NSMutableDictionary new];
	instanceMethods = [NSMutableDictionary new];
	functions = [NSMutableDictionary new];
	
	return self;
}

- (void) dealloc
{
	[parserDelegateStack release];
	[elementClasses release];
	[header release];
	[content release];
	[classMethods release];
	[instanceMethods release];
	[sourcePath release];
	[super dealloc];
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
	return [parserDelegateStack lastObject];
}

- (void) pushParserDelegate: (id <GSDocParserDelegate>)aDelegate
{
	[parserDelegateStack addObject: aDelegate];
}

- (void) popParserDelegate
{
	[parserDelegateStack removeObjectAtIndex: [parserDelegateStack count] - 1];
}

- (NSSet *) transparentElements
{
	return transparentElements;
}

- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
     attributes:(NSDictionary *)attributeDict
{
	//NSLog (@"begin elementName: <%@>", elementName, qName);

	if ([transparentElements containsObject: elementName])
		return;

	ASSIGN(currentAttributes, attributeDict);

	id parserDelegate = [self parserDelegate];

	/* When we have a parser delegate registered for the new element name, 
	   we switch this delegate, otherwise we continue with the current one. */
	if ([self elementClassForName: elementName] != nil)
	{
		parserDelegate = [[self elementClassForName: elementName] new];
	}
	[self pushParserDelegate: parserDelegate];

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
	//NSLog (@"end elementName: <%@>:<%@>", elementName, qName);

	NSString* trimmed = [content stringByTrimmingCharactersInSet: 
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	/* For some tags, we do nothing but we store their content in our content 
	   accumulator. The next handled element can retrieve the accumulated 
	   content. For example:
	   <desc><i>A boat<i> on <j>the</j> river.</desc>
	   if i and j are transparent elements, the parser behaves exactly as if we 
	   parsed:
	   <desc>A boat on the river.</desc> */
	if ([transparentElements containsObject: elementName])
		return;

	[[self parserDelegate] parser: self endElement: elementName withContent: trimmed];

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
		ETAssert(nil != header);
		[header setClassName: [attributeDict objectForKey: @"name"]];
		[header setSuperClassName: [attributeDict objectForKey: @"super"]];
	}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	/* When we parse a class, we parse the declared child element too */
	if ([elementName isEqualToString: @"declared"])
	{
		ETAssert(nil != header);
		[header setDeclaredIn: trimmed];
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

- (void) setGSDocDirectory: (NSString*) aPath
{
  [aPath retain];
  [sourcePath release];
  sourcePath = aPath;
}

- (void) setGSDocFile: (NSString*) aName
{
  [aName retain];
  [classFile release];
  classFile = aName;
}

- (void) outputMethods: (NSDictionary*) methods withTitle: (NSString*) aTitle on: (NSMutableString*) html
{
  NSArray* unsortedTasks = [methods allKeys];
  NSArray* tasks = [unsortedTasks sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
  if ([tasks count] > 0)
  {
    [html appendFormat: @"<h3>%@</h3>", aTitle];
  }
  for (int i=0; i<[tasks count]; i++)
  {
    NSString* key = [tasks objectAtIndex: i];
    [html appendFormat: @"<h4>%@</h4>", key];
    NSArray* unsortedArray = [methods objectForKey: key];
    NSArray* array = [unsortedArray sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    for (int j=0; j<[array count]; j++)
    {
      Method* m = [array objectAtIndex: j];
      [html appendString: [m content]];
    }
  }
}

- (void) outputClassMethodsOn: (NSMutableString *) html  
{
  [self outputMethods: classMethods withTitle: @"Class Methods" on: html];
}

- (void) outputInstanceMethodsOn: (NSMutableString *) html  
{
  [self outputMethods: instanceMethods withTitle: @"Instance Methods" on: html];
}

- (void) outputFunctionsOn: (NSMutableString*) html
{
  [self outputMethods: functions withTitle: @"Functions" on: html];
}

- (NSString*) getMethods
{
  NSMutableString* methods = [NSMutableString new];
  [self outputFunctionsOn: methods];
  [self outputClassMethodsOn: methods];
  [self outputInstanceMethodsOn: methods];
  return [methods autorelease];
}

- (NSString*) getHeader
{
  // Check if there's an overview file, if so use it
  NSFileManager* fm = [NSFileManager defaultManager];
  NSString* overviewFile = [NSString stringWithFormat: @"%@-overview.html",
                            [classFile stringByDeletingPathExtension]];
  if ([fm fileExistsAtPath: overviewFile])
  {
    [header setFileOverview: overviewFile];
  }
  return [header content];
}

- (void) addClassMethod: (Method *)aMethod
{
	NSMutableArray *array = [classMethods objectForKey: [aMethod task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[classMethods setObject: array forKey: [aMethod task]];
		[array release];
	}
	[array addObject: aMethod];
}

- (void) addInstanceMethod: (Method *)aMethod
{
	NSMutableArray *array = [instanceMethods objectForKey: [aMethod task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[instanceMethods setObject: array forKey: [aMethod task]];
		[array release];
	}
	[array addObject: aMethod];
}

- (void) addFunction: (Function *)aFunction
{
	NSMutableArray* array = [functions objectForKey: [aFunction task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[functions setObject: array forKey: [aFunction task]];
		[array release];
	}
	[array addObject: aFunction];
}

- (void) setHeader: (Header *)aHeader
{
	ASSIGN(header, aHeader);
}

@end

