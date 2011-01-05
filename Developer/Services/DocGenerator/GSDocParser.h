/**
	<abstract>GSDoc parser that can drive a DocPageWeaver through 
	CodeDocWeaving protocol.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Authors:  Nicolas Roard,
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocPageWeaver.h"

@class DocHeader, DocMethod, DocFunction;
@class GSDocParser;

/** @group GSDoc Parsing */
@protocol GSDocParserDelegate
- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)anElement
  withAttributes: (NSDictionary *)theAttributes;
- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)anElement
    withContent: (NSString *)aContent;
@end

/** @group GSDoc Parsing */
@interface GSDocParser : NSObject <GSDocParserDelegate>
{
	id <CodeDocWeaving> weaver; /* Weak ref */
	NSXMLParser *xmlParser;
	NSMutableArray *parserDelegateStack;
	NSString *indentSpaces;
	NSString *indentSpaceUnit;
	NSMutableDictionary *elementClasses;
	NSSet *symbolElements;
	NSMutableDictionary *substitutionElements;
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
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict;

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmedContent;

- (NSDictionary *) currentAttributes;
- (NSString *) argTypeFromArgsAttributes: (NSDictionary *)attributeDict;

@end

#if DEBUG_PARSING
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
#else
#define BEGINLOG()
#define CONTENTLOG()
#define ENDLOG()
#define ENDLOG2(a, b)
#define ENDLOG3(a, b, c)
#endif
