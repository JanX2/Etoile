//
//  JabberRootIdentity.h
//  Jabber
//
//  Created by David Chisnall on 02/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JabberIdentity.h"

@interface JabberRootIdentity : JabberIdentity {
	NSMutableDictionary * resources;
	NSMutableArray * resourceList;
}
- (id) initWithRosterItem:(TRXMLNode*)_xml;
- (void) addResource:(JID*)_jid;
- (NSArray*) resources;
- (JabberIdentity*) identityForResource:(NSString*)resource;
@end
