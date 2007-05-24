//
//  PresenceLogController.h
//  Jabber
//
//  Created by David Chisnall on 22/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PresenceLogController : NSWindowController {
	IBOutlet NSTextView * view;
	NSString * myStatus;
}

@end
