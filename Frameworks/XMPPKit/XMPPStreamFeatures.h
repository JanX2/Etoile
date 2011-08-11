//
//  XMPPStreamFeatures.h
//  Jabber
//
//  Created by David Chisnall on 05/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EtoileXML/ETXMLNullHandler.h>

/**
 * The XMPPStreamFeatures class is used to parse the features from a stream stanza.
 * This is used during logging in, to determine which features a server supports.
 */
@interface XMPPStreamFeatures : ETXMLNullHandler {
	NSMutableDictionary * features;
}
@end
