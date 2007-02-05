//
//  TRXMLNullHandler.h
//  Jabber
//
//  Created by David Chisnall on 15/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TRXMLParser.h"

@interface TRXMLNullHandler : NSObject<TRXMLParserDelegate> {
	unsigned int depth;
	id parser;
	id<NSObject,TRXMLParserDelegate> parent;
	id key;
	id value;
}
- (id) initWithXMLParser:(id)parser parent:(id<NSObject,TRXMLParserDelegate>)parent key:(id)aKey;
- (void) addChild:(id)aChild forKey:aKey;
- (void) notifyParent;
@end
