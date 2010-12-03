//
//  GSDocParser.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocPageWeaver.h"

@class DocHeader, DocMethod, DocFunction;
@class GSDocParser;

@protocol GSDocParserDelegate
- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)anElement
  withAttributes: (NSDictionary *)theAttributes;
- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)anElement
    withContent: (NSString *)aContent;
@end

/**
 * <title>GSDocParser</title>
 * Author: Nicolas Roard
 * <abstract> 
 * GSDoc parser + HTML Writing
 * </abstract>
 */

@interface GSDocParser : NSObject <GSDocParserDelegate>
{
	id <CodeDocWeaving> weaver; /* Weak ref */
	NSXMLParser *xmlParser;
	NSMutableArray *parserDelegateStack;
	NSString *indentSpaces;
	NSString *indentSpaceUnit;
	NSMutableDictionary *elementClasses;
	NSDictionary *substitutionElements;
	NSSet *etdocElements;
	NSMutableString *content;
	NSDictionary *currentAttributes;
}

- (id) initWithString: (NSString *)aContent;

- (void) setWeaver: (id <CodeDocWeaving>)aDocWeaver;
- (id <CodeDocWeaving>) weaver;
- (void) parseAndWeave;

/**
 * Reinitialize the current CDATA stored in the content variable.
 * @task Parsing
 */
- (void) newContent;

- (Class) elementClassForName: (NSString *)anElementName;
- (id <GSDocParserDelegate>) parserDelegate;
- (void) pushParserDelegate: (id <GSDocParserDelegate>)aDelegate;
- (void) popParserDelegate;
- (NSString *) indentSpaces;

/**
 * NSXMLParse delegate method.
 * @task Parsing
 */
- (void) parser: (NSXMLParser*) parser didStartElement:(NSString *)elementName
                                          namespaceURI:(NSString *)namespaceURI
                                         qualifiedName:(NSString *)qName
                                            attributes:(NSDictionary *)attributeDict;

/**
 * NSXMLParse delegate method.
 * @task Parsing
 */
- (void) parser: (NSXMLParser*) parser foundCharacters:(NSString *)string;

/**
 * NSXMLParse delegate method.
 * @task Parsing
 */
- (void) parser: (NSXMLParser*) parser   didEndElement:(NSString *)elementName
                                          namespaceURI:(NSString *)namespaceURI
                                         qualifiedName:(NSString *)qName;

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)anElement
  withAttributes: (NSDictionary *)theAttributes;

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)anElement
    withContent: (NSString *)aContent;

- (NSDictionary *) currentAttributes;
- (NSString *) argTypeFromArgsAttributes: (NSDictionary *)attributeDict;

@end


#define BEGINLOG() \
	NSLog(@"%@BEGIN <%@>", [parser indentSpaces], elementName);
#define CONTENTLOG() \
	NSLog(@"%@%@", [parser indentSpaces], trimmed);
#define ENDLOG() \
	NSLog(@"%@END   <%@> %@\n\n", [parser indentSpaces]);
#define ENDLOG2(a, b) \
	NSLog(@"%@END   <%@> %@\n\n", [parser indentSpaces], elementName, [NSString stringWithFormat: @"%@, %@", a, b]);
#define ENDLOG3(a, b, c) \
	NSLog(@"%@END   <%@> %@\n\n", [parser indentSpaces], elementName, [NSString stringWithFormat: @"%@, %@, %@", a, b, c]);
