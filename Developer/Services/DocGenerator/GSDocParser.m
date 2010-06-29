//
//  GSDocParser.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GSDocParser.h"
#import "GSDocFunction.h"
#import "DescriptionParser.h"

@implementation GSDocParser

- (id) init
{
  self = [super init];
  content = [NSMutableString new];
  transparentNodes = [NSMutableArray new];
  [self setTransparentNodes];
  return self;
}

- (void) dealloc
{
  [content release];
  [transparentNodes release];
  [argType release];
  [super dealloc];
}

- (void) setTransparentNodes
{
  [transparentNodes addObject: @"var"];
  [transparentNodes addObject: @"code"];
  [transparentNodes addObject: @"em"];
  [transparentNodes addObject: @"br"];
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
    attributes:(NSDictionary *)attributeDict 
{
  if ([transparentNodes containsObject: elementName])
  {
    // do nothing...
  }
  else if ([elementName isEqualToString: @"function"])
  {
    [currentParser release];
    NSString* aName = [attributeDict objectForKey: @"name"];
    NSString* aType = [attributeDict objectForKey: @"type"];
    currentParser = [GSDocFunction newWithName: aName andReturnType: aType];
  }
  else if ([elementName isEqualToString: @"arg"])
  {
    [argType release];
    argType = [attributeDict objectForKey: @"type"];
    [argType retain];
  }
  else
  {
    [currentParser startElement: elementName withAttributes: attributeDict];
  }
}

- (void) parser: (NSXMLParser*) parser 
foundCharacters:(NSString *)string
{
  [content appendString: string];
}

- (void) parser: (NSXMLParser*) parser   
  didEndElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
{
  NSString* trimmed = [content stringByTrimmingCharactersInSet: 
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([transparentNodes containsObject: elementName])
  {
    // Do nothing...
  }
  else if ([elementName isEqualToString: @"function"])
  {
    [currentParser appendToRawDescription: trimmed];
    
    DescriptionParser* descParser = [DescriptionParser new];
    [descParser parse: [currentParser rawDescription]];
//    NSLog (@"parsed <%@>", [currentParser rawDescription]);
    [currentParser addInformationFrom: descParser];
    
    [currentParser htmlDescription];
    [currentParser release];
    currentParser = nil;
  }
  else if ([elementName isEqualToString: @"arg"])
  {
    [currentParser addParameter: [Parameter newWithName: trimmed andType: argType]];
    [self newContent];
  }  
  else
  {
    [currentParser endElement: elementName withContent: trimmed];
    [self newContent];
  }
}

@end
