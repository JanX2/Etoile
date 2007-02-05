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
+ (id) TRXMLNodeWithType:(NSString*)type;
+ (id) TRXMLNodeWithType:(NSString*)type attributes:(NSDictionary*)_attributes;
- (id) initWithType:(NSString*)type;
- (id) initWithType:(NSString*)type attributes:(NSDictionary*)_attributes;
- (NSString*) type;
- (NSString*) stringValueWithFlags:(NSDictionary *)flags;
- (NSString*) stringValue;
- (NSSet*) getChildrenWithName:(NSString*)_name;
- (unsigned int) children;
- (NSEnumerator*) childEnumerator;
- (NSArray*) elements;
- (void) addChild:(id)anElement;
- (void) addCData:(id)newCData;
- (NSString *) cdata;
- (void) setCData:(NSString*)newCData;
- (NSString*) get:(NSString*)attribute;
- (void) set:(NSString*)attribute to:(NSString*) value;
@end
