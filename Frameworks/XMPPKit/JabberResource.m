//
//  JabberResource.m
//  Jabber
//
//  Created by David Chisnall on 02/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "JabberResource.h"
#include "../Macros.h"

@implementation JabberResource
- (id) init
{
	SUPERINIT
	root = nil;
	return self;
}

- (JabberIdentity*) root
{
	return root;
}

- (void) setRoot:(JabberIdentity*)identity
{
	[root release];
	root = [identity retain];
}
@end
