//
//  CompareHack.m
//  Jabber
//
//  Created by David Chisnall on 17/12/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JabberIdentity.h"
#import "CompareHack.h"

int compareTest(id a, id  b, void* none)
{
	return [a compare:b];
}

int compareByPriority(id a, id  b, void* none)
{
	return [a compareByPriority:b];
}
