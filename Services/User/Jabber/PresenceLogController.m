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
#import "NSTextView+ClickableLinks.h"

#define GET_METHOD(type, x) - (type) x { return x; }
#define COMPARE_METHOD(ivar, ivarName) - (NSComparisonResult) compareBy ## ivarName:(id)other { return [ivar compare:[other ivar]]; }
@interface PresenceLogEntry : NSObject {
	NSDate * date;
	NSString * user;
	NSString * statusMessage;
}
@end
@implementation PresenceLogEntry
GET_METHOD(NSDate*, date)
GET_METHOD(NSString*,user)
GET_METHOD(NSString*,statusMessage)
COMPARE_METHOD(date,Date)
COMPARE_METHOD(user,User)
COMPARE_METHOD(statusMessage,Status)
@end

@implementation PresenceLogController
- (void) awakeFromNib
{
	NSNotificationCenter * localCenter = [NSNotificationCenter defaultCenter];
	lastStatus = [[NSMutableDictionary alloc] init];
	[localCenter addObserver:self
					selector:@selector(newPresence:)
						name:@"TRXMPPPresenceChanged"
					  object:nil];
	[localCenter addObserver:self
					selector:@selector(presenceChanged:)
						name:@"LocalPresenceChangedNotification"
					  object:nil];		
}

- (void) presenceChanged:(NSNotification *)notification
{
	NSDictionary * dict = [notification userInfo];
	NSString * status = [dict objectForKey:@"status"];
	if(status != myStatus)
	{
		[myStatus release];
		myStatus = [status retain];
	}
}

- (void) newPresence:(NSNotification *)notification
{
	NSString * name = [[notification object] name];
	NSDictionary * dict = [notification userInfo];
	NSString * oldMessage = [lastStatus objectForKey:name];
	NSString * newMessage = [dict objectForKey:@"NewStatus"];
	/* If the pressence has changed, and is not an echo */
	if(newMessage != nil
	   &&
	   ![oldMessage isEqualToString:newMessage]
	   &&
	   ![newMessage isEqualToString:@""]
	   &&
	   ![newMessage isEqualToString:myStatus]
	   &&
	   ![newMessage isEqualToString:[Presence displayStringForPresence:
		   [[dict objectForKey:@"NewPresence"] unsignedCharValue]]]
	   )
	{
		[lastStatus setObject:newMessage forKey:name];
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
		[view makeLinksClickable];
	}
}
@end
