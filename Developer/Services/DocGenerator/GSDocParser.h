//
//  GSDocParser.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@protocol GSDocParserElement
- (void) startElement: (NSString*) anElement withAttributes: (NSDictionary*) theAttributes;
- (void) endElement: (NSString*) anElement withContent: (NSString*) aContent;
@end

@interface GSDocParser : NSObject {
  NSMutableString* content;
  id currentParser;
  NSMutableArray* transparentNodes;
  NSString* argType;
}

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

@end
