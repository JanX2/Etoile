//
//  JabberIdentity.h
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JID.h"
#import "TRXMLNullHandler.h"
#import "Presence.h"
#import "Dispatcher.h"


@interface JabberIdentity : TRXMLNullHandler {
	id person;
	JID * jid;
	NSString * subscription;
	NSString * group;
	NSString * name;
	Presence * presence;
	int priority;
	int basePriority;
}
- (id) initWithJID:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group forPerson:(id)_person;
- (void) setPresence:(Presence*)_presence;
- (id) person;
- (void) person:(id)_person;
- (NSString*) name;
- (NSString*) group;
- (JID*) jid;
- (Presence*) presence;
- (int) priority;
- (NSComparisonResult) compareByPriority:(JabberIdentity*)_other;
- (NSComparisonResult) compareByJID:(JabberIdentity*)_other;
@end
