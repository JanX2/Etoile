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
	
@interface RosterGroup : NSObject {
	NSMutableDictionary * peopleByName;
	NSString * name;
	NSMutableArray * people;
	id roster;
}
+ (id) groupWithRoster:(id)_roster;
- (id) initWithRoster:(id)_roster;
- (NSString*) groupName;
- (void) groupName:(NSString*)_name;
- (JabberPerson*) personNamed:(NSString*)_name;
- (void) addIdentity:(JabberIdentity*)_identity;
- (void) removeIdentity:(JabberIdentity*)_identity;
- (unsigned int) numberOfPeopleInGroupMoreOnlineThan:(unsigned int)hide;
- (JabberPerson*) personAtIndex:(unsigned int)_index;

- (NSComparisonResult) compare:(RosterGroup*)otherGroup;

@end
