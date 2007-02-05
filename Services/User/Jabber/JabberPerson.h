//
//  JabberPerson.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "JID.h"
#import "TRXML/TRXMLNode.h"
#import "Presence.h"
#import "JabberIdentity.h"

@interface JabberPerson : NSObject <PresenceHandler> {
	NSMutableDictionary * identities;
	NSMutableArray * identityList;
	unsigned int identityCount;
	NSString * name;
	NSString * group;
	id roster;
	unsigned int hash;
}
+ (id) jabberPersonWithIdentity:(JabberIdentity*)_identity forRoster:(id)_roster;
- (id) initWithIdentity:(JabberIdentity*)_identity forRoster:(id)_roster;
- (void) addIdentity:(JabberIdentity*)_identity;
- (void) removeIdentity:(JabberIdentity*)_identity;
- (NSString*) group;
- (void) group:(NSString*)_group;
- (NSString*) name;
- (unsigned int) identities;
- (JabberIdentity*) defaultIdentity;
- (NSArray*) identityList;
- (JabberIdentity*) identityForJID:(JID*)jid;
- (void) name:(NSString*)_name;
//- (TRXMLNode*) rosterNodeForJID:(JID*)_jid;
- (NSComparisonResult) compare:(JabberPerson*)otherPerson;
@end

