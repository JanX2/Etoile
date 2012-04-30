//
//  AccountWindowController.h
//  Jabber
//
//  Created by David Chisnall on 22/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <XMPPKit/JID.h>
#import "SCAccountInfoManager.h"

@interface AccountWindowController : NSWindowController {
	__unsafe_unretained IBOutlet NSTextField * jidBox;
	__unsafe_unretained IBOutlet NSTextField * serverBox;
}

- (IBAction) yes:(id)sender;
- (IBAction) no:(id)sender;
@end
