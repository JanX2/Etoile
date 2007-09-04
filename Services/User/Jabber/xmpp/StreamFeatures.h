//
//  StreamFeatures.h
//  Jabber
//
//  Created by David Chisnall on 05/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ETXMLNullHandler.h"

/**
 * The StreamFeatures class is used to parse the features from a stream stanza.
 * This is used during logging in, to determine which features a server supports.
 */
@interface StreamFeatures : ETXMLNullHandler {
	NSMutableDictionary * features;
}
@end
