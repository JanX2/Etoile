//
//  DiscoItems.h
//  Jabber
//
//  Created by David Chisnall on 14/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EtoileXML/ETXMLNullHandler.h>


@interface DiscoItems : ETXMLNullHandler {
	NSMutableArray * items;
	NSString * node;
}
- (NSArray*) items;
- (NSString*) node;
@end
