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
	
	header = [Header new];
	method = [Method new];
	content = [NSMutableString new];
	classMethods = [NSMutableDictionary new];
	instanceMethods = [NSMutableDictionary new];
	functions = [NSMutableDictionary new];
	ASSIGN(currentTask, @"Default");
	
	return self;
}

- (void) dealloc
{
	[header release];
	[method release];
	[pfunction release];
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

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
//    NSLog (@"begin elementName: <%@>", elementName, qName);
  if ([elementName isEqualToString: @"head"]) { head = YES; }
  
  if ([elementName isEqualToString: @"author"]) 
  {
    [header addAuthor: [attributeDict objectForKey: @"name"]];
  }
  
  if ([elementName isEqualToString: @"class"]) 
  {
    [header setClassName: [attributeDict objectForKey: @"name"]];
    [header setSuperClassName: [attributeDict objectForKey: @"super"]];
  }

  /*
  if ([elementName isEqualToString: @"overview"]) 
  {
    NSString* fileOverview = [attributeDict objectForKey: @"file"];
    if (fileOverview)
    {
      NSString* overviewFilePath = [NSString stringWithFormat: @"%@/%@", sourcePath, fileOverview];
      [header setFileOverview: overviewFilePath];
    }
  }
  */
  
  if ([elementName isEqualToString: @"method"])
  {
    [method release];
    method = [Method new];
    [method setReturnType: [attributeDict objectForKey: @"type"]];
    if ([[attributeDict objectForKey: @"factory"] isEqualToString: @"yes"]) 
    {
      [method setIsClassMethod: YES];
    }
    inMethod = YES;
  }
  
  if ([elementName isEqualToString: @"arg"])
  {
    [argType release];
    argType = [attributeDict objectForKey: @"type"];
    argType = [argType stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [argType retain];
  }

  if ([elementName isEqualToString: @"function"])
  {
    [pfunction release];
    pfunction = [Function new];
    [pfunction setReturnType: [attributeDict objectForKey: @"type"]];
    [pfunction setFunctionName: [attributeDict objectForKey: @"name"]];
    inFunction = YES;
  }
  
  if ([elementName isEqualToString: @"macro"])
  {
//    [macro release];
//    macro = [Macro new];
  }
  
  /*
  if ([elementName isEqualToString: @"task"])
  {
    if ([content length] >0) 
    {
      NSString* trimmed = [content stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if ([trimmed length] > 0)
      {
//        NSLog (@"description: <%@>", trimmed);
        if (inMethod)
        {
          [method appendToDescription: trimmed];
        }
        if (inFunction)
        {
          [pfunction appendToDescription: trimmed];
        }
      }
    }
    if (![elementName isEqualToString: @"var"]
      && ![elementName isEqualToString: @"code"]) 
    {
      [self newContent];
    }
  }
  */
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
  [content appendString: string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
  //  NSLog (@"end elementName: <%@>:<%@>", elementName, qName);
  NSString* trimmed = [content stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (head) 
  {
    if ([elementName isEqualToString: @"title"]) 
    { 
      [header setTitle: trimmed];
    }
    if ([elementName isEqualToString: @"abstract"])
    {
      [header setAbstract: trimmed];
    }
  }
  if ([elementName isEqualToString: @"head"]) { head = NO; }
  
  if ([elementName isEqualToString: @"declared"]) 
  {
    [header setDeclaredIn: trimmed];
  }
  if ([elementName isEqualToString: @"overview"]) 
  {
    [header setOverview: trimmed];
  }
  if (inMethod)
  {
    if ([elementName isEqualToString: @"sel"]) 
    {
      [method addSelector: trimmed];
    }
    if ([elementName isEqualToString: @"arg"]) 
    {
      [method addParameter: trimmed ofType: argType];
    }
    if ([elementName isEqualToString: @"desc"]) 
    {
      [method appendToDescription: trimmed];
    }
  }
  if (inFunction)
  {
    if ([elementName isEqualToString: @"arg"]) 
    {
      [pfunction addParameter: trimmed ofType: argType];
    }
    if ([elementName isEqualToString: @"desc"]) 
    {
      [pfunction appendToDescription: trimmed];
    }    
  }

  if ([elementName isEqualToString: @"function"])
  {
    DescriptionParser* descParser = [DescriptionParser new];
    [descParser parse: [pfunction functionRawDescription]];
    NSLog (@"parsed <%@>", [pfunction functionRawDescription]);
    [pfunction addInformationFrom: descParser];
    [descParser release];
    NSLog (@"pfunction task: <%@>", [pfunction task]);
    
    NSMutableArray* array = [functions objectForKey: [pfunction task]];
    if (array == nil)
    {
      array = [NSMutableArray new];
      [functions setObject: array forKey: [pfunction task]];
      [array release];
    }
    [array addObject: pfunction];
  }
  
  if ([elementName isEqualToString: @"method"]) 
  {
//    NSLog (@"end of method <%@>, put in task <%@>", [method signature], currentTask);
    DescriptionParser* descParser = [DescriptionParser new];
    [descParser parse: [method methodRawDescription]];
    [method addInformationFrom: descParser];
    NSLog (@"method (%@) is in task %@", [method signature], [method task]);
    if ([method isClassMethod])
    {
      NSMutableArray* array = [classMethods objectForKey: [method task]];
      if (array == nil)
      {
        array = [NSMutableArray new];
        [classMethods setObject: array forKey: [method task]];
        [array release];
      }
      [array addObject: method];
    }
    else
    {
      NSMutableArray* array = [instanceMethods objectForKey: [method task]];
      if (array == nil)
      {
        array = [NSMutableArray new];
        [instanceMethods setObject: array forKey: [method task]];
        [array release];
      }
      [array addObject: method];
    }
  }
  
  /*
  if ([elementName isEqualToString: @"task"])
  {
    [currentTask release];
    currentTask = [trimmed retain];
  }
   */
  
  if (![elementName isEqualToString: @"var"]
    && ![elementName isEqualToString: @"code"]) 
  {
    [self newContent];
  }
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

@end

