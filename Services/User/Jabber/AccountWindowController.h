//
//  AccountWindowController.h
//  Jabber
//
//  Created by David Chisnall on 22/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface AccountWindowController : NSWindowController {
	IBOutlet NSTextField * jidBox;
	IBOutlet NSTextField * serverBox;
	IBOutlet NSButton * yes;
	IBOutlet NSButton * no;
}
@end
