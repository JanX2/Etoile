//
//  ChatLogMenuController.m
//  Jabber
//
//  Created by David Chisnall on 18/02/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <XMPPKit/JabberPerson.h>
#import <XMPPKit/ChatLog.h>
#import "ChatLogMenuController.h"
#import "MessageWindowController.h"
#import "RosterController.h"

@implementation ChatLogMenuController
- (IBAction) openChatLog:(id)sender
{
	id frontWindowController = [[NSApp mainWindow] delegate];
	NSMutableString * logFolder = [NSMutableString stringWithString:[ChatLog logPath]];
	if([frontWindowController isKindOfClass:[MessageWindowController class]])
	{
		JabberPerson * person = [[(MessageWindowController*)frontWindowController conversation] remotePerson];
		if([[NSFileManager defaultManager] fileExistsAtPath:logFolder])
		{
			[logFolder appendFormat:@"%@/%@", [person group], [person name]];
		}
	}
	[[NSWorkspace sharedWorkspace] openFile:logFolder];
}
@end
