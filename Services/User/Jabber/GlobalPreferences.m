//
//  GlobalPreferences.m
//  Jabber
//
//  Created by David Chisnall on 09/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GlobalPreferences.h"
#import "JabberApp.h"
#import "Presence.h"
#include <stdio.h>

inline NSString * colourString(NSColor * colour)
{
	NSColor * rgbColour = [colour colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	return [NSString stringWithFormat: @"%f %f %f %f",
		[rgbColour redComponent],
		[rgbColour greenComponent],
		[rgbColour blueComponent],
		[rgbColour alphaComponent]];
}

inline NSColor * colourFromString(NSString* string)
{
	float r = 0;
	float g = 0;
	float b = 0;
	float a = 0;
	if(string == nil)
	{
		return nil;
	}
	if(sscanf([string UTF8String], "%f %f %f %f", &r, &g, &b, &a) != 4)
    {
		return nil;
    }
	return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}
static GlobalPreferences * sharedPreferenceObject = nil;

@implementation GlobalPreferences
+ (id) sharedPreferenceObject
{
	if(sharedPreferenceObject == nil)
	{
		sharedPreferenceObject = [[GlobalPreferences alloc] init];
	}
	return sharedPreferenceObject;
}
- (void) save
{
	[data writeToFile:fileName atomically:YES];
}

- (id) init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	fileName = 	[[NSString stringWithFormat:@"%@/Library/Application Support/Jabber/settings.plist",
		[@"~" stringByExpandingTildeInPath]]
		retain];
	NSFileManager * fileManager = [[NSFileManager alloc] init];
	if([fileManager fileExistsAtPath:fileName])
	{
		data = [[NSMutableDictionary dictionaryWithContentsOfFile:fileName] retain];
	}
	else
	{
		NSString * path = [NSString stringWithFormat:@"%@/Library/Application Support/Jabber",
			[@"~" stringByExpandingTildeInPath]];
		if(![fileManager fileExistsAtPath:path])
		{
			[fileManager createDirectoryAtPath:path attributes:nil];
		}
		data = [[NSMutableDictionary alloc] init];
	}
	[fileManager release];
	return self;
}

- (void) hidePresences:(unsigned char)_presence
{
	[data setValue:[NSNumber numberWithUnsignedChar:_presence] forKey:@"HiddenPresences"];
	[self save];
	[[NSApp delegate] redrawRosters];
}

- (unsigned char) hiddenPresences
{
	return [[data valueForKey:@"HiddenPresences"] unsignedCharValue];
}

- (BOOL) isExpanded:(NSString*)_groupName
{
	return [[[data objectForKey:@"ExpandedGroups"] objectForKey:_groupName] boolValue];
}

- (void) setExpanded:(NSString*)_groupName to:(BOOL)_value
{
	NSMutableDictionary * groupList = [data objectForKey:@"ExpandedGroups"];
	if(groupList == nil)
	{
		groupList = [[NSMutableDictionary alloc] init];
		[data setObject:groupList forKey:@"ExpandedGroups"];
		//We can safely release this even though we are about to use it, since it is retained by the data object
		[groupList release];
	}
	[groupList setValue:[NSNumber numberWithBool:_value] forKey:_groupName];
	[self save];
}

- (NSColor*) colourForPresence:(unsigned char)_presence
{
	NSMutableDictionary * presenceList = [data objectForKey:@"PresenceColours"];
	if(presenceList == nil)
	{
		presenceList = [[NSMutableDictionary alloc] init];
		[data setObject:presenceList forKey:@"PresenceColours"];
		[presenceList release];		
	}
	NSColor * presenceColour = colourFromString([presenceList objectForKey:[Presence displayStringForPresence:_presence]]);
	if(presenceColour == nil)
	{
		switch(_presence)
		{
			case PRESENCE_ONLINE:
			case PRESENCE_CHAT:
				presenceColour = [NSColor colorWithCalibratedRed:0.0f 
													   green:1.0f
														blue:0.0f
													   alpha:1.0f];
				break;
			case PRESENCE_AWAY:
				presenceColour = [NSColor colorWithCalibratedRed:1.0f 
													   green:1.0f
														blue:0.0f
													   alpha:1.0f];
				break;
			case PRESENCE_XA:
				presenceColour = [NSColor colorWithCalibratedRed:1.0f 
													   green:0.5f
														blue:0.0f
													   alpha:1.0f];
				break;
			case PRESENCE_DND:
				presenceColour = [NSColor colorWithCalibratedRed:1.0f 
													   green:0.0f
														blue:0.0f
													   alpha:1.0f];
				break;
			case PRESENCE_OFFLINE:
			default:
				presenceColour = [NSColor colorWithCalibratedRed:0.8f 
														   green:0.8f
															blue:0.8f
														   alpha:1.0f];
		}
		[presenceList setObject:colourString(presenceColour) forKey:[Presence displayStringForPresence:_presence]];
		[self save];
	}
	return presenceColour;
}
- (void) setColour:(NSColor*)_colour forPresence:(unsigned char)_presence
{
	NSMutableDictionary * presenceList = [data objectForKey:@"PresenceColours"];
	if(presenceList == nil)
	{
		presenceList = [[NSMutableDictionary alloc] init];
		[data setObject: presenceList forKey:@"PresenceColours"];
		//We can safely release this even though we are about to use it, since it is retained by the data object
		[presenceList release];
	}
	[presenceList setObject:colourString(_colour) forKey:[Presence displayStringForPresence:_presence]];
	[self save];
}

- (NSString*) customMessageNamed:(NSString*)_name
{
	return [[data objectForKey:@"CustomMessages"] objectForKey:_name];
}
- (unsigned char) customPresenceNamed:(NSString*)_name
{
	return [[[data objectForKey:@"CustomPresence"] objectForKey:_name] unsignedCharValue];
}
- (void) setCustomPresence:(unsigned char)_presence withMessage:(NSString*)_message named:(NSString*)_name
{
	NSMutableDictionary * storage = [data objectForKey:@"CustomMessages"];
	if(storage == nil)
	{
		storage = [[NSMutableDictionary alloc] init];
		[data setObject:storage forKey:@"CustomMessages"];
		[storage release];
	}
	[storage setObject:_message forKey:_name];
	storage = [data objectForKey:@"CustomPresence"];
	if(storage == nil)
	{
		storage = [[NSMutableDictionary alloc] init];
		[data setObject:storage forKey:@"CustomPresence"];
		[storage release];
	}
	[storage setObject:[NSNumber numberWithUnsignedChar:_presence] forKey:_name];
	[self save];
}
- (NSArray*) customPresences
{
	NSMutableDictionary * presences = [data objectForKey:@"CustomPresence"];
	return [presences keysSortedByValueUsingSelector:@selector(compare:)];
}
- (NSSound*) sound:(NSString*)_name
{
	if(_name == nil || [_name isEqualToString:@""])
	{
		return nil;
	}
	NSSound * sound = [NSSound soundNamed:_name];
	if(sound == nil)
	{
		sound = [[[NSSound alloc] initWithContentsOfFile:_name byReference:YES] autorelease];
	}
	return sound;	
}

- (NSSound*) onlineSound
{
	return [self sound:[self onlineSoundName]];
}
- (NSSound*) offlineSound
{
	return [self sound:[self offlineSoundName]];
}
- (NSSound*) messageSound
{
	return [self sound:[self messageSoundName]];
}
- (NSString*) onlineSoundName
{
	return [data objectForKey:@"OnlineSound"];
}
- (NSString*) offlineSoundName
{
	return [data objectForKey:@"OfflineSound"];
}
- (NSString*) messageSoundName
{
	return [data objectForKey:@"MessageSound"];
}
- (void) setOnlineSound:(NSString*)_path
{
	[data setObject:_path forKey:@"OnlineSound"];
	[self save];
}
- (void) setOfflineSound:(NSString*)_path
{
	[data setObject:_path forKey:@"OfflineSound"];
	[self save];
}
- (void) setMessageSound:(NSString*)_path
{
	[data setObject:_path forKey:@"MessageSound"];
	[self save];
}
@end

