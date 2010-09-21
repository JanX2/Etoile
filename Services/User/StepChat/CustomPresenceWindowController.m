//
//  CustomPresenceWindowController.m
//  Jabber
//
//  Created by David Chisnall on 10/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "CustomPresenceWindowController.h"
#import "JabberApp.h"
#import "TRUserDefaults.h"

@implementation CustomPresenceWindowController

- (void) windowWillLoad
{
	presences = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CustomPresence"] keysSortedByValueUsingSelector:@selector(compare:)] retain];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return [presences count];
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
	return [presences indexOfObject:aString];
}

- (void) showPresenceNamed:(NSString*)_name
{
	[message setString:[[NSUserDefaults standardUserDefaults] customMessageNamed:_name]];
	[presence selectItemAtIndex:([[NSUserDefaults standardUserDefaults] customPresenceNamed:_name] /10) - 1];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
	[self showPresenceNamed:[presences objectAtIndex:[name indexOfSelectedItem]]];
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString
{
	NSEnumerator * enumerator = [presences objectEnumerator];
	NSString * completedString;
	unsigned int length = [uncompletedString length];
	while((completedString = [enumerator nextObject]))
	{
		if([completedString length] > length)
		{
			if([[completedString substringToIndex:length] caseInsensitiveCompare:uncompletedString] == NSOrderedSame)
			{
				[self showPresenceNamed:completedString];
				return completedString;
			}
		}
	}
	return uncompletedString;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)_index
{
	return [presences objectAtIndex:_index];
}

- (IBAction) okay:(id) sender
{
	//TODO:  Make this less of an hack
	[(JabberApp*)[NSApp delegate] setPresence:(([presence indexOfSelectedItem] + 1) * 10) withMessage:[message  string]];
	if(![[name stringValue] isEqualToString:@""])
	{
		[[NSUserDefaults standardUserDefaults] setCustomPresence:(([presence indexOfSelectedItem] + 1) * 10) withMessage:[message string] named:[name stringValue]];
	}
	[[self window] close];
}
- (IBAction) cancel:(id) sender
{
	[[self window] close];
}
- (void) dealloc
{
	[presences release];
	[super dealloc];
}
@end
