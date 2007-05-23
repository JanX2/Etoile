//
//  MessageWindowController.h
//  Jabber
//
//  Created by David Chisnall on 18/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Conversation.h"
#import "Message.h"
#import "Presence.h"
#import "ChatLog.h"

@interface MessageWindowController  : NSWindowController <ConversationDelegate> {
	IBOutlet NSTextView * messageBox;
	IBOutlet NSScrollView * messageBoxBox;
	IBOutlet NSTextView * editingBox;
	IBOutlet NSScrollView * editingBoxBox;
	IBOutlet NSTextField * presenceBox;
	IBOutlet NSTextField * presenceIconBox;
	IBOutlet NSPopUpButton * recipientBox;
	Conversation * conversation;
	unsigned int unread;
	ChatLog * log;
	unsigned char presence;
	BOOL hack;
}
- (IBAction) changeRemoteJid:(id)sender;
- (void) displayMessage:(Message*)_message incoming:(BOOL)_in;
- (Conversation*) conversation;
@end
