//
//  XMPPResource.m
//  Jabber
//
//  Created by David Chisnall on 02/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XMPPResource.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPResource
- (id) init
{
	SUPERINIT
	root = nil;
	return self;
}

- (XMPPIdentity*) root
{
	return root;
}

- (void) setRoot:(XMPPIdentity*)identity
{
	root = identity;
}
@end
