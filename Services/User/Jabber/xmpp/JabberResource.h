//
//  JabberResource.h
//  Jabber
//
//  Created by David Chisnall on 02/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JabberIdentity.h"

@interface JabberResource : JabberIdentity {
	JabberIdentity * root;
}
- (JabberIdentity*) root;
- (void) setRoot:(JabberIdentity*)identity;
@end
