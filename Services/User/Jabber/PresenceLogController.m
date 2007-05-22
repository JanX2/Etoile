//
//  PresenceLogController.m
//  Jabber
//
//  Created by David Chisnall on 22/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PresenceLogController.h"


@implementation PresenceLogController
- (void) awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(newPresence:)
												 name:@"TRXMPPPresenceChanged"
											   object:nil];
}

- (void) newPresence:(NSNotification *)notification
{
	NSDictionary * dict = [notification userInfo];
	NSString * oldMessage = [dict objectForKey:@"OldStatus"];
	NSString * newMessage = [dict objectForKey:@"NewStatus"];
	if(newMessage != nil
	   &&
	   ![oldMessage isEqualToString:newMessage]
	   &&
	   ![newMessage isEqualToString:@""])
	{
		NSString * name = [[notification object] name];
		NSString * emoString = [NSString stringWithFormat:@"%@:\n\t%@\n", name, newMessage];
		NSAttributedString * emoText = [[NSAttributedString alloc] initWithString:emoString];
		[[view textStorage] insertAttributedString:emoText atIndex:0];
		[emoText release];
	}
}
@end
