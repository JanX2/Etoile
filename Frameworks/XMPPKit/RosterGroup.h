//
//  RosterGroup.h
//  Jabber
//
//  Created by David Chisnall on Sun Jul 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JabberIdentity.h"
#import "JabberPerson.h"
	
/**
 * The RosterGroup class represents a group in the roster.
 */
@interface RosterGroup : NSObject {
	NSMutableDictionary * peopleByName;
	NSString * name;
	NSMutableArray * people;
	id roster;
}
/**
 * Create a new group in the specified roster.
 */
+ (id) groupWithRoster:(id)_roster;
/**
 * Initialise a new group for the specified roster.
 */
- (id) initWithRoster:(id)_roster;
/**
 * Returns the name of the group.
 */
- (NSString*) groupName;
/**
 * Set the group name.
 */
- (void) groupName:(NSString*)_name;
/**
 * Returns the person in the group with the specified name.
 */
- (JabberPerson*) personNamed:(NSString*)_name;
/**
 * Adds a new identity to the group.  This identity will either be added to an 
 * existing person, or have a new person created for it, depending on the name.
 */
- (void) addIdentity:(JabberIdentity*)_identity;
/**
 * Remove the specified identity from the group.  This may also remove a person 
 * from the group if the relevant person only has a single identity.
 */
- (void) removeIdentity:(JabberIdentity*)_identity;
/**
 * Returns the number of people in the group who are more online than the specified
 * value.
 */
- (unsigned int) numberOfPeopleInGroupMoreOnlineThan:(unsigned int)hide;
/**
 * Returns the person at the specified index.
 */
- (JabberPerson*) personAtIndex:(unsigned int)_index;

/**
 * Compares two roster groups by name.
 */
- (NSComparisonResult) compare:(RosterGroup*)otherGroup;

@end
