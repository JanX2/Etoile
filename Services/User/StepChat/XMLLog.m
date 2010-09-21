//
//  XMLLog.m
//  Jabber
//
//  Created by David Chisnall on 12/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XMLLog.h"
#import "JabberApp.h"
#import <EtoileFoundation/EtoileFoundation.h>

static NSDictionary * inColour;
static NSDictionary * outColour;

@implementation XMLLog
+ (void) initialize
{
	inColour = [[NSDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.0f 
																			 green:0.0f
																			  blue:1.0f
																			 alpha:1.0f]
											forKey:NSForegroundColorAttributeName] retain];
	outColour = [[NSDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:1.0f 
																			  green:0.0f
																			   blue:0.0f
																			  alpha:1.0f]
											 forKey:NSForegroundColorAttributeName] retain];	
}

+ (void) logIncomingXML:(NSString*)xml
{
	NSTextView * textView = [(JabberApp*)[NSApp delegate] xmlLogBox];
	NSString * inXML = [NSString stringWithFormat:@"IN:\n%@\n\n", xml];
	[[textView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:inXML
																					attributes:inColour] autorelease]];
	[textView display];
	[textView scrollRangeToVisible:NSMakeRange([[textView textStorage] length],0)];
}
+ (void) logOutgoingXML:(NSString*)xml
{
	NSTextView * textView = [(JabberApp*)[NSApp delegate] xmlLogBox];
	NSString * outXML = [NSString stringWithFormat:@"OUT:\n%@\n\n", xml];
	[[textView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:outXML
																					attributes:outColour] autorelease]];
	
	[textView display];
	[textView scrollRangeToVisible:NSMakeRange([[textView textStorage] length],0)];
}
@end
