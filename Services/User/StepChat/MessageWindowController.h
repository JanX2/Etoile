//
//  MessageWindowController.h
//  Jabber
//
//  Created by David Chisnall on 18/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <XMPPKit/XMPPConversation.h>
#import <XMPPKit/XMPPMessage.h>
#import <XMPPKit/XMPPPresence.h>
#import <XMPPKit/XMPPChatLog.h>

@interface MessageWindowController  : NSWindowController <XMPPConversationDelegate> {
	__unsafe_unretained IBOutlet NSTextView * messageBox;
	__unsafe_unretained IBOutlet NSScrollView * messageBoxBox;
	__unsafe_unretained IBOutlet NSTextView * editingBox;
	__unsafe_unretained IBOutlet NSScrollView * editingBoxBox;
	__unsafe_unretained IBOutlet NSTextField * presenceBox;
	__unsafe_unretained IBOutlet NSTextField * presenceIconBox;
	__unsafe_unretained IBOutlet NSPopUpButton * recipientBox;
	__unsafe_unretained IBOutlet NSImageView * avatarBox;
	XMPPConversation * conversation;
	unsigned int unread;
	XMPPChatLog * log;
	unsigned char presence;
	BOOL hack;
}
- (IBAction) changeRemoteJid:(id)sender;
- (void) displayMessage:(XMPPMessage*)_message incoming:(BOOL)_in;
- (XMPPConversation*) conversation;
@end
