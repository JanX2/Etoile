//
//  PreferenceWindowController.m
//  Jabber
//
//  Created by David Chisnall on 19/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "PreferenceWindowController.h"
#import "Presence.h"
#import "RosterController.h"
#import "MessageWindowController.h"
#import "TRUserDefaults.h"


@implementation PreferenceWindowController
+ (void) initialize
{
	NSUserDefaults * settings = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary * colours = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.75f
																		 green:0.41f
																		  blue:0.0f
																		 alpha:1.0f]],
		@"Away",
		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.69f
																		 green:0.0f
																		  blue:0.0f
																		 alpha:1.0f]],
		@"Do Not Disturb",
		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.75f
																		 green:0.41f
																		  blue:0.0f
																		 alpha:1.0f]],
		@"Extended Away",
		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0f
																		 green:0.35f
																		  blue:0.0f
																		 alpha:1.0f]],
		@"Free For Chat",
		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.57f
																		 green:0.57f
																		  blue:0.57f
																		 alpha:1.0f]],
		@"Offline",
		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0f
																		 green:0.35f
																		  blue:0.0f
																		 alpha:1.0f]],
		@"Online",
		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.57f
																		 green:0.57f
																		  blue:0.57f
																		 alpha:1.0f]],
		@"Unknown",
		nil];
	
	//TODO: Set this from a .plist file so it can be locallised without recompiling.
	[settings registerDefaults:[NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSDictionary dictionaryWithObjectsAndKeys:@"Drinking Coffee", @"Coffee", nil],
		@"CustomMessages",
		[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedChar:40], @"Coffee", nil],
		@"CustomPresence",
		[NSDictionary dictionary],
		@"ExpandedGroups",
		[NSNumber numberWithUnsignedChar:60],
		@"HiddenPresences",
		@"Hero",
		@"MessageSound",
		@"Pop",
		@"OfflineSound",
		@"Submarine",
		@"OnlineSound",
		colours,
		@"PresenceColours",
        nil]];
}

- (void)showWindow:(id)_sender
{
	NSUserDefaults * pref = [NSUserDefaults standardUserDefaults];
	[chatColour setColor:[pref colourForPresence:PRESENCE_CHAT]];
	[onlineColour setColor:[pref colourForPresence:PRESENCE_ONLINE]];
	[awayColour setColor:[pref colourForPresence:PRESENCE_AWAY]];
	[xaColour setColor:[pref colourForPresence:PRESENCE_XA]];
	[dndColour setColor:[pref colourForPresence:PRESENCE_DND]];
	[offlineColour setColor:[pref colourForPresence:PRESENCE_OFFLINE]];
	[unknownColour setColor:[pref colourForPresence:PRESENCE_UNKNOWN]];
	NSString * soundName = [pref stringForKey:@"OnlineSound"];
	if(soundName != nil)
	{
		[onlineSoundBox setStringValue:soundName];
	}
	soundName = [pref stringForKey:@"OfflineSound"];
	if(soundName != nil)
	{
		[offlineSoundBox setStringValue:soundName];
	}
	soundName = [pref stringForKey:@"MessageSound"];
	if(soundName != nil)
	{
		[messageSoundBox setStringValue:soundName];
	}
	[super showWindow:_sender];
}
- (void) loadSoundForComboBox:(NSComboBox*)_box
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];	
    if ([openPanel runModalForDirectory:@"/System/Library/Sounds" 
								file:nil
							   types:[NSSound soundUnfilteredFileTypes]] == NSOKButton) 
	{
		[_box setStringValue:[[openPanel filenames] objectAtIndex:0]];
    }
}
- (IBAction) selectOnlineSound:(id)_sender
{
	[self loadSoundForComboBox:onlineSoundBox];
}
- (IBAction) selectOfflineSound:(id)_sender
{
	[self loadSoundForComboBox:offlineSoundBox];
}
- (IBAction) selectMessageSound:(id)_sender
{
	[self loadSoundForComboBox:messageSoundBox];
}
- (void)windowWillClose:(NSNotification *)aNotification
{
	NSUserDefaults * pref = [NSUserDefaults standardUserDefaults];
	[pref setColour:[chatColour color] forPresence:PRESENCE_CHAT];
	[pref setColour:[onlineColour color] forPresence:PRESENCE_ONLINE];
	[pref setColour:[awayColour color] forPresence:PRESENCE_AWAY];
	[pref setColour:[xaColour color] forPresence:PRESENCE_XA];
	[pref setColour:[dndColour color] forPresence:PRESENCE_DND];
	[pref setColour:[offlineColour color] forPresence:PRESENCE_OFFLINE];
	[pref setColour:[unknownColour color] forPresence:PRESENCE_UNKNOWN];
	[pref setObject:[onlineSoundBox stringValue] forKey:@"OnlineSound"];
	[pref setObject:[offlineSoundBox stringValue] forKey:@"OfflineSound"];
	[pref setObject:[messageSoundBox stringValue] forKey:@"MessageSound"];
}

- (void) playSound:(NSString*)_soundName
{
	NSSound * sound = [NSSound soundNamed:_soundName];
	if(sound == nil)
	{
		sound = [[[NSSound alloc] initWithContentsOfFile:_soundName byReference:YES] autorelease];
	}
	[sound play];
}

- (IBAction) playOnlineSound:(id)_sender
{
	[self playSound:[onlineSoundBox stringValue]];
}
- (IBAction) playOfflineSound:(id)_sender
{
	[self playSound:[offlineSoundBox stringValue]];
}
- (IBAction) playMessageSound:(id)_sender
{
	[self playSound:[messageSoundBox stringValue]];
}

@end
