//
//  Query_jabber_iq_roster.h
//  Jabber
//
//  Created by David Chisnall on 12/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TRXMLNullHandler.h"

@interface Query_jabber_iq_roster : TRXMLNullHandler {
	NSMutableArray * identities;
}

@end
