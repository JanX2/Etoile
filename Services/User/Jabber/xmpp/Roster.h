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

@class ServiceDiscovery;
/**
 * Protocol to be implemented by a roster UI component.
 */
@protocol RosterDelegate
/**
 * Update the display of the specified object.
 */
- (void) update:(id)_object;
//- (void) authorisationRequestedFor:(JID*)_jid;
@end

/**
 * The Roster class implements the roster.  At the basic level, the roster is
 * simply a collection of people.  This class maintains the list, and allows new
 * people to be added and removed.
 */
@interface Roster : NSObject  <PresenceHandler,IqHandler> {
	NSMutableDictionary * peopleByJID;
	NSMutableDictionary * groupsByName;
	NSMutableArray * groups;
	ServiceDiscovery * disco;
	BOOL connected;
	//TODO: Dispatcher should be in Account
	Dispatcher * dispatcher;
	unsigned char initialStatus;
	NSString * initialMessage;
	id account;
	id <RosterDelegate, NSObject> delegate;
	id connection;
}
/**
 * Initialise a roster for a specified account.
 */
- (Roster*) initWithAccount:(id)_account;
/**
 * Add items to the roster from an iq with type result containing one or more 
 * roster items.
 */
- (void) addRosterFromQuery:(Iq*)rosterQuery;

/**
 * Sets the initial presence.  This will be the presence when connecting is
 * complete.  It would probably be more sensibly handled in XMPPConnection or 
 * XMPPAccount.  It is currently here so that the client can set itself as online
 * once the latest copy of the roster has been received.
 */
- (void) setInitialStatus:(unsigned char)_status withMessage:(NSString*)_message;
/**
 * Takes the roster offline.  This sets the presence of all identities to 
 * unknown (since we can not be certain of any online states while we are not on 
 * the XMPP network).
 */
- (void) offline;

/**
 * Sets the delegate.
 */
- (void) setDelegate:(id <RosterDelegate, NSObject>)_delegate;

/**
 * Triggers an update of the specified object in the roster.  This would be better
 * handled by notifications.
 */
- (void) update:(id)_object;

/**
 * Returns a person for a given JID if one exists in the roster.
 */
- (JabberPerson*) personForJID:(JID*)_jid;
/**
 * Returns the group for a given name.
 */
- (RosterGroup*) groupNamed:(NSString*)_groupName;

/** 
 * Returns the group at a given index.
 */
- (RosterGroup*) groupForIndex:(int)_index;
/**
 * Returns the group at a specified index when only groups containing people more
 * online than the given onlineState value are counted.
 */
- (RosterGroup*) groupForIndex:(int)_index ignoringPeopleLessOnlineThan:(unsigned int)onlineState;

/**
 * Returns the number of groups.
 */
- (int) numberOfGroups;
/**
 * Returns the number of groups when only groups containing people more online than
 * the given onlineState value are counted.
 */
- (int) numberOfGroupsContainingPeopleMoreOnlineThan:(unsigned int)onlineState;

//Post a notification in case it successes or fails.
/**
 * Adds the specified JID to the roster, with the given name in the given group.
 */
- (void) subscribe:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group;
/**
 * Removes the specified JID from the roster.
 */
- (void) unsubscribe:(JID*)_jid;
/**
 * Authorises the specified JID to add the user to their roster.
 */
- (void) authorise:(JID*)_jid;
/**
 * Remove the authorisation granted to the specified JID.  This JID will no longer
 * receive presence stanzas from you.
 */
- (void) unauthorise:(JID*)_jid;
/**
 * Renames an identity.  This will cause the identity to be assigned to a new person.
 */
- (void) setName:(NSString*)aName forIdentity:(JabberIdentity*)anIdentity;
/**
 * Moves an identity to a new group.  This will cause the identity to be assigned to a new person.
 */
- (void) setGroup:(NSString*)aGroup forIdentity:(JabberIdentity*)anIdentity;
/**
 * Returns the roster's delegate.
 */
- (id) delegate;
/**
 * Returns the dispatcher used by this roster.
 */
- (Dispatcher*) dispatcher;
/**
 * Returns the connection used by this roster.
 */
- (id) connection;
@end

