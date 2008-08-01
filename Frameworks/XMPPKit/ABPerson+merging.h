//
//  ABPerson+merging.h
//  Jabber
//
//  Created by David Chisnall on 19/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

@interface ABPerson (Merging) 
/**
 * Attempts to find an existing person in the address book who
 * might correspond to this one.
 */
- (ABPerson*) findExistingPerson;
/**
 * Attempts to merge the fields in the argument in to
 * this person.  Returns an array of conlicting properties.
 */
- (NSArray*) mergePerson:(ABPerson*)aPerson;
@end
