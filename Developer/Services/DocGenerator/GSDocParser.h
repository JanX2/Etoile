//
//  GSDocParser.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class Header, Method, Function;
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
	NSMutableString *content;
	
	Header *header;
	BOOL head;
	BOOL inMethod, inFunction;
	BOOL inMacro;
	
	NSString *declaredIn;
	NSMutableDictionary *classMethods;
	NSMutableDictionary *instanceMethods;
	NSMutableDictionary *functions;
	NSMutableDictionary *macros;
	
	Method *method;
	NSString *argType;
	Function *pfunction;
	
	NSString *sourcePath;
	NSString *classFile;
	NSString *currentTask;
}

/**
 * Set the path of the directory containing the gsdoc sources;
 * This is used while resolving referencings to the overview file.
 * @task Configuration
 */
- (void) setGSDocDirectory: (NSString*) aPath;

/**
 * Set the name of the gsdoc file. Used to fetch the overview
 * file if present, using the name "MyFile-overview.html";
 * This override the manual inclusion via the overview tag
 * in the gsdoc file.
 * @task Configuration
 */
- (void) setGSDocFile: (NSString*) aName;

/**
 * This method takes one of the dictionary populated
 * by the gsdoc parsing containing the methods, sort
 * them alphabetically by Tasks, and output the result
 * formated in HTML in the string passed in argument.
 * A title is also added, which uses a <h3> header.
 * @task Writing HTML
 */
- (void) outputMethods: (NSDictionary*) methods
             withTitle: (NSString*) aTitle
                    on: (NSMutableString*) html;

/**
 * Convenience method to generate the class methods output
 * @task Writing HTML
 */
- (void) outputClassMethodsOn: (NSMutableString *) html;

/**
 * Convenience method to generate the instance methods output
 * @task Writing HTML
 */
- (void) outputInstanceMethodsOn: (NSMutableString *) html;

/**
 * Convenience method to generate the list of functions output
 * @task Writing HTML
 */
- (void) outputFunctionsOn: (NSMutableString*) html;

- (NSString*) getHeader;
- (NSString*) getMethods;

/**
 * Reinitialize the current CDATA stored in the content variable.
 * @task Parsing
 */
- (void) newContent;

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

@end
