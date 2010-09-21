//
//  NSUserDefaultsWithColour.m
//  Jabber
//
//  Created by David Chisnall on 02/11/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <XMPPKit/Presence.h>
#import "TRUserDefaults.h"

@implementation NSUserDefaults(TRJabberAdditions)
- (void) setColour:(NSColor *)_colour forPresence:(unsigned char)_presence
{
	NSMutableDictionary * colours = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryForKey:@"PresenceColours"]];
	[colours setObject:[NSArchiver archivedDataWithRootObject:_colour] 
				forKey:[Presence displayStringForPresence:_presence]];
	[self setObject:colours forKey:@"PresenceColours"];
}

- (NSColor*) colourForPresence:(unsigned char)_presence;
{
	return [NSUnarchiver unarchiveObjectWithData:[[self dictionaryForKey:@"PresenceColours"] objectForKey:[Presence displayStringForPresence:_presence]]];
}

- (void) setColour:(NSColor *)_colour forKey:(NSString *)_key
{
    NSData * data=[NSArchiver archivedDataWithRootObject:_colour];	
    [self setObject:data forKey:_key];
}


- (NSColor *) colourForKey:(NSString *)_key
{
    NSColor * colour=nil;	
    NSData * data=[self dataForKey:_key];
	
    if(data != nil)
	{
        colour=(NSColor *)[NSUnarchiver unarchiveObjectWithData:data];
	}	
    return colour;
}

- (unsigned char) presenceForKey:(NSString*)_key
{
	return (unsigned char)[self integerForKey:_key];
}

- (void) setPresence:(unsigned char)_presence forKey:(NSString *)_key
{
	[self setInteger:(int) _presence forKey:_key];
}

- (NSSound*) soundForKey:(NSString*)_key
{
	NSSound * sound = [NSSound soundNamed:[self stringForKey:_key]];
	if(sound == nil)
	{
		sound = [[[NSSound alloc] initWithContentsOfFile:[self stringForKey:_key] byReference:YES] autorelease];
	}
	return sound;	
}

- (void) setExpanded:(NSString*)_group to:(BOOL)_expanded
{
	NSMutableDictionary * groups = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryForKey:@"ExpandedGroups"]];
	[groups setObject:[NSNumber numberWithBool:_expanded] forKey:_group];
	[self setObject:groups forKey:@"ExpandedGroups"];
}
- (BOOL) expandedGroup:(NSString*)_group
{
	return [[[self dictionaryForKey:@"ExpandedGroups"] objectForKey:_group] boolValue];
}

- (NSString*) customMessageNamed:(NSString*)_name
{
	return [[self dictionaryForKey:@"CustomMessages"] objectForKey:_name];
}

- (unsigned char) customPresenceNamed:(NSString*)_name
{
	return [[[self dictionaryForKey:@"CustomPresences"] objectForKey:_name] unsignedCharValue];
}

- (void) setCustomPresence:(unsigned char)_presence withMessage:(NSString*)_message named:(NSString*)_name
{
	NSMutableDictionary * presences = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryForKey:@"CustomPresences"]];
	NSMutableDictionary * messages = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryForKey:@"CustomMessages"]];
	
	[presences setObject:[NSNumber numberWithUnsignedChar:_presence] forKey:_name];
	[messages setObject:_message forKey:_name];
	
	[self setObject:presences forKey:@"CustomPresences"];	
	[self setObject:messages forKey:@"CustomMessages"];	
}
@end

