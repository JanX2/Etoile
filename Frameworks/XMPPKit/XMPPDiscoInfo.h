//
//  XMPPDiscoInfo.h
//  Jabber
//
//  Created by David Chisnall on 14/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EtoileXML/ETXMLNullHandler.h>

@interface XMPPDiscoInfo : ETXMLNullHandler {
	NSMutableArray * identities;
	NSMutableArray * features;
	NSString * node;
}
- (NSArray*) identities;
- (NSArray*) features;
- (NSString*) node;
@end
