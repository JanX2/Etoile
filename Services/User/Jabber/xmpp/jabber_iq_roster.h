//
//  jabber_iq_roster.h
//  Jabber
//
//  Created by David Chisnall on 03/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EtoileXML/ETXMLNullHandler.h>

/**
 * I don't think this class is used anymore...
 */
@interface jabber_iq_roster : ETXMLNullHandler {
	NSMutableArray * items;
}

@end
