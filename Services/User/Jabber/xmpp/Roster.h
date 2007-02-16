//
//  Roster.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dispatcher.h"
#import "RosterGroup.h"
#import "JabberPerson.h"
#import "Presence.h"
#import "Iq.h"

@protocol RosterDelegate
- (void) update:(id)_object;
//- (void) authorisationRequestedFor:(JID*)_jid;
@end

@interface Roster : NSObject  <PresenceHandler,IqHandler> {
	NSMutableDictionary * peopleByJID;
	NSMutableDictionary * groupsByName;
	NSMutableArray * groups;
	BOOL connected;
	//TODO: Dispatcher should be in Account
	Dispatcher * dispatcher;
	unsigned char initialStatus;
	NSString * initialMessage;
	id account;
	id <RosterDelegate, NSObject> delegate;
	id connection;
}
- (id) initWithAccount:(id)_account;
- (void) addRosterFromQuery:(Iq*)rosterQuery;

- (void) setInitialStatus:(unsigned char)_status withMessage:(NSString*)_message;
- (void) offline;

- (void) setDelegate:(id <RosterDelegate, NSObject>)_delegate;

- (void) update:(id)_object;

- (JabberPerson*) personForJID:(JID*)_jid;
- (RosterGroup*) groupNamed:(NSString*)_groupName;

- (RosterGroup*) groupForIndex:(int)_index;
- (RosterGroup*) groupForIndex:(int)_index ignoringPeopleLessOnlineThan:(unsigned int)onlineState;

- (int) numberOfGroups;
- (int) numberOfCroupsContainingPeopleMoreOnlineThat:(unsigned int)onlineState;

//Post a notification in case it successes or fails.
- (void) subscribe:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group;
- (void) unsubscribe:(JID*)_jid;
- (void) authorise:(JID*)_jid;
- (void) unauthorise:(JID*)_jid;

- (id) delegate;
@end

