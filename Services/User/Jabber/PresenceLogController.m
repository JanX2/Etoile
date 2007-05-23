//
//  PresenceLogController.m
//  Jabber
//
//  Created by David Chisnall on 22/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PresenceLogController.h"
#import "Presence.h"
#import "TRUserDefaults.h"


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
	   ![newMessage isEqualToString:@""]
	   &&
	   ![newMessage isEqualToString:[Presence displayStringForPresence:
		   [[dict objectForKey:@"NewPresence"] unsignedCharValue]]])
	{
		NSString * name = [[notification object] name];
		NSString * date = [[NSDate  date] descriptionWithCalendarFormat:@"%H:%M"
															   timeZone:nil
																 locale:[[NSUserDefaults standardUserDefaults] 
																	  dictionaryRepresentation]];
		NSAttributedString * headline = [[NSAttributedString alloc]
			initWithString:[NSString stringWithFormat:@"%@ - %@:\n", date, name]
				attributes:PRESENCE_COLOUR_DICTIONARY(([[dict objectForKey:@"NewPresence"] unsignedCharValue]))];

		NSString * emoString = [NSString stringWithFormat:@"\t%@\n", newMessage];
		
		NSAttributedString * emoText = [[NSAttributedString alloc] initWithString:emoString];
		[[view textStorage] insertAttributedString:emoText atIndex:0];
		[[view textStorage] insertAttributedString:headline atIndex:0];
		[emoText release];
		[headline release];
	}
}
@end
