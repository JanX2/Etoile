//
//  Query_jabber_iq_roster.h
//  Jabber
//
//  Created by David Chisnall on 12/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EtoileXML/ETXMLNullHandler.h>

/**
 * Handler for a query result in the jabber:iq:roster namespace.  This is used by 
 * the server to deliver a series of roster entries.  This class, when used as a 
 * parser delegate, will create an array of identities.  The identities will then
 * be returned to the parent via the standard mechanism.
 */
@interface Query_jabber_iq_roster : ETXMLNullHandler {
	NSMutableArray * identities;
	NSMutableArray * deletedIdentities;
}

@end
