//
//  StreamFeatures.h
//  Jabber
//
//  Created by David Chisnall on 05/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TRXML/TRXMLNullHandler.h"

@interface StreamFeatures : TRXMLNullHandler {
	NSMutableDictionary * features;
}
@end
