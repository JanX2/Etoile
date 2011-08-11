//
//  ChatLogMenuController.m
//  Jabber
//
//  Created by David Chisnall on 18/02/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <XMPPKit/XMPPPerson.h>
#import <XMPPKit/XMPPChatLog.h>
#import "ChatLogMenuController.h"
#import "MessageWindowController.h"
#import "RosterController.h"

@implementation ChatLogMenuController
- (IBAction) openChatLog:(id)sender
{
	id frontWindowController = [[NSApp mainWindow] delegate];
	NSMutableString * logFolder = [NSMutableString stringWithString:[XMPPChatLog logPath]];
	if([frontWindowController isKindOfClass:[MessageWindowController class]])
	{
		XMPPPerson * person = [[(MessageWindowController*)frontWindowController conversation] remotePerson];
		if([[NSFileManager defaultManager] fileExistsAtPath:logFolder])
		{
			[logFolder appendFormat:@"%@/%@", [person group], [person name]];
		}
	}
	[[NSWorkspace sharedWorkspace] openFile:logFolder];
}
@end
