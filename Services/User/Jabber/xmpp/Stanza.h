//
//  Stanza.h
//  Jabber
//
//  Created by David Chisnall on 19/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ETXMLNullHandler.h"

/**
 * Class implementing behaviour common to the three core protocol stanza types.
 */
@interface Stanza : ETXMLNullHandler {
	NSMutableDictionary * children;
}
/**
 * Returns a dictionary containing the children.  The key under which each is
 * stored is defined in the StanzaFactory, as is the class used to parse it.
 */
- (NSDictionary*) children;
@end
