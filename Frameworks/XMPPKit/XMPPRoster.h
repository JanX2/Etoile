//
//  XMPPRoster.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPDispatcher.h"
#import "XMPPRosterGroup.h"
#import "XMPPPerson.h"
#import "XMPPPresence.h"
#import "XMPPInfoQueryStanza.h"

@class XMPPServiceDiscovery;
/**
 * Protocol to be implemented by a roster UI component.
 */
@protocol RosterDelegate
/**
 * Update the display of the specified object.
 */
- (void) update:(id) anObject;
//- (void) authorisationRequestedFor:(JID*)_jid;
@end

/**
 * The Roster class implements the roster.  At the basic level, the roster is
 * simply a collection of people.  This class maintains the list, and allows new
 * people to be added and removed.
 */
@interface XMPPRoster : NSObject  <PresenceHandler,XMPPInfoQueryStanzaHandler> {
	NSMutableDictionary * peopleByJID;
	NSMutableDictionary * groupsByName;
	NSMutableArray * groups;
	NSMutableSet * queriedServers;
	XMPPServiceDiscovery * disco;
	BOOL connected;
	//TODO: XMPPDispatcher should be in Account
	XMPPDispatcher * dispatcher;
	unsigned char initialStatus;
	NSString * initialMessage;
	id account;
	id <RosterDelegate, NSObject> delegate;
	id connection;
}
/**
 * Initialise a roster for a specified account.
 */
- (XMPPRoster*) initWithAccount:(id)anAccount;
/**
 * Add items to the roster from an iq with type result containing one or more 
 * roster items.
 */
- (void) addRosterFromQuery:(XMPPInfoQueryStanza*)rosterQuery;

/**
 * Sets the initial presence.  This will be the presence when connecting is
 * complete.  It would probably be more sensibly handled in XMPPConnection or 
 * XMPPAccount.  It is currently here so that the client can set itself as online
 * once the latest copy of the roster has been received.
 */
- (void) setInitialStatus:(unsigned char)aStatus withMessage:(NSString*)aMessage;
/**
 * Takes the roster offline.  This sets the presence of all identities to 
 * unknown (since we can not be certain of any online states while we are not on 
 * the XMPP network).
 */
- (void) offline;

/**
 * Sets the delegate.
 */
- (void) setDelegate:(id <RosterDelegate, NSObject>)aDelegate;

/**
 * Triggers an update of the specified object in the roster.  This would be better
 * handled by notifications.
 */
- (void) update:(id)anObject;

/**
 * Returns a person for a given JID if one exists in the roster.
 */
- (XMPPPerson*) personForJID:(JID*)aJid;
/**
 * Returns the group for a given name.
 */
- (XMPPRosterGroup*) groupNamed:(NSString*)aGroupName;

/** 
 * Returns the group at a given index.
 */
- (XMPPRosterGroup*) groupForIndex:(int)anIndex;
/**
 * Returns the group at a specified index when only groups containing people more
 * online than the given onlineState value are counted.
 */
- (XMPPRosterGroup*) groupForIndex:(int)anIndex ignoringPeopleLessOnlineThan:(unsigned int)onlineState;

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
- (void) subscribe:(JID*)aJid withName:(NSString*)aName inGroup:(NSString*)aGroup;
/**
 * Removes the specified JID from the roster.
 */
- (void) unsubscribe:(JID*)aJid;
/**
 * Authorises the specified JID to add the user to their roster.
 */
- (void) authorise:(JID*)aJid;
/**
 * Remove the authorisation granted to the specified JID.  This JID will no longer
 * receive presence stanzas from you.
 */
- (void) unauthorise:(JID*)aJid;
/**
 * Renames an identity.  This will cause the identity to be assigned to a new person.
 */
- (void) setName:(NSString*)aName group:(NSString*)aGroup forIdentity:(XMPPIdentity*)anIdentity;
/**
 * Moves an identity to a new group.  This will cause the identity to be assigned to a new person.
 */
- (void) setGroup:(NSString*)aGroup forIdentity:(XMPPIdentity*)anIdentity;
/**
 * Returns the roster's delegate.
 */
- (id) delegate;
/**
 * Returns the dispatcher used by this roster.
 */
- (XMPPDispatcher*) dispatcher;
/**
 * Returns the connection used by this roster.
 */
- (id) connection;
/**
 * Returns the service discovery interface.
 */
- (XMPPServiceDiscovery*) disco;
@end

