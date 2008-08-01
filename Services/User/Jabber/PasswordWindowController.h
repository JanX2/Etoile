//
//  PasswordWindowController.h
//  Jabber
//
//  Created by David Chisnall on 22/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <XMPPKit/JID.h>

@interface PasswordWindowController : NSWindowController {
	IBOutlet NSTextField * question;
	IBOutlet NSTextField * passwordBox;
	JID * myJID;
}
- (id) initWithWindowNibName:(NSString*)windowNibName forJID:(JID*)_jid;
- (void) yes:(id)sender;
- (void) no:(id)sender;
@end
