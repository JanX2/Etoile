//
//  TRXMLNode.h
//  Jabber
//
//  Created by David Chisnall on Thu Apr 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXMLParserDelegate.h"
#import "TRXMLParser.h"

/**
 * The TRXMLNode class represents a single XML element, which may contain 
 * character data or other nodes.  It can be used with the parser directly
 * to create an object structure representing the XML hierarchy.  More commonly,
 * it is used to generate the tree directly and then output XML.
 *
 * This class almost certainly uses some non-standard terminology relating to
 * XML, which should probably be fixed at some point.  Eventually, this class
 * should probably be retired.  Currently, most of the XMPP code only uses the
 * +TRXMLNodeWithType, +TRXMLNodeWithType:attributes:, -addChild:, -addCData:
 * and -stringValue: methods. All others should be considered deprecated.
 *
 * Note: TRXMLNode objects are always mutable, and should be treated as such.
 */
@interface TRXMLNode : NSObject <TRXMLParserDelegate> {
	NSMutableArray * elements;
	unsigned int children;
	NSMutableDictionary * childrenByName;
	NSMutableDictionary * attributes;
	id parser;
	id parent;
	NSString * nodeType;
	NSMutableString * plainCDATA;
}
/**
 * Create a new instance of the class with the specified type.  [TRXMLNode TRXMLNodeWithType:@"foo"] give an object representing the XML string "<foo />"
 */
+ (id) TRXMLNodeWithType:(NSString*)type;
/**
 * Create a new instance of the class with the specified type and attributes.  
 */
+ (id) TRXMLNodeWithType:(NSString*)type attributes:(NSDictionary*)_attributes;
/**
 * Initialise a created instance with an XML node name.
 */
- (id) initWithType:(NSString*)type;
/**
 * Initialise an instance with the specified node name and attributes.
 */
- (id) initWithType:(NSString*)type attributes:(NSDictionary*)_attributes;
- (NSString*) type;
/**
 * Generate an XML string representing the node.
 */
- (NSString*) stringValue;
/**
 * Produces an XML string without pretty printing.
 */
- (NSString*) unindentedStringValue;
- (NSSet*) getChildrenWithName:(NSString*)_name;
- (unsigned int) children;
- (NSArray*) elements;
- (void) addChild:(id)anElement;
- (void) addCData:(id)newCData;
- (NSString *) cdata;
- (void) setCData:(NSString*)newCData;
- (NSString*) get:(NSString*)attribute;
- (void) set:(NSString*)attribute to:(NSString*) value;
@end
