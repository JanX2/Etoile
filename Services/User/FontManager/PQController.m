/*
 * PQController.m - Font Manager
 *
 * Controller for installed font list & main window.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */

#import "PQController.h"
#import "PQCompat.h"

@implementation PQController

- (id) init
{
	[super init];
	
	/* Create an array of font families */
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSArray *fontFamilyNames = [fontManager availableFontFamilies];
	
	fontFamilies = [[NSMutableArray alloc] init];
	
	NSEnumerator *familyNamesEnum = [fontFamilyNames objectEnumerator];
	NSString *currentName;

	while (currentName = [familyNamesEnum nextObject])
	{
		NSArray *members = [fontManager availableMembersOfFontFamily: currentName];

		NSMutableArray *newMembers = [[NSMutableArray alloc] init];
		NSArray *currentMember;
		NSEnumerator *membersEnum = [members objectEnumerator];

		while (currentMember = [membersEnum nextObject])
		{
			[newMembers addObject:[currentMember objectAtIndex:1]];
		}
		
		PQFontFamily *newFontFamily =
			[[PQFontFamily alloc] initWithName: currentName members: newMembers];
    [fontFamilies addObject:newFontFamily];
	}
	
	[fontFamilies sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	RETAIN(fontFamilies);

	return self;
}

- (void) awakeFromNib
{
}

/* Groups [table] view data source code */

- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
	return 1;
}

- (id) tableView: (NSTableView *)aTableView
	objectValueForTableColumn: (NSTableColumn *)aTableColumn
	           row: (int)rowIndex
{
	return @"All";
}

/* Fonts [outline] view data source code */

- (id) outlineView: (NSOutlineView *)outlineView
	objectValueForTableColumn: (NSTableColumn *)tableColumn
	byItem: (id)item
{
	if ([item isKindOfClass:[PQFontFamily class]])
	{
		return [item name];
	}
	else if ([item isKindOfClass:[NSString class]])
	{
		return item;
	}
	
	/* Else: something is wrong */
	return nil;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	if (item == nil) /* Is this even necessary */
	{
		return YES;
	}
	else if ([item isKindOfClass:[PQFontFamily class]])
	{
		return [item hasMultipleMembers];
	}
	/* else */
	return NO;
}

- (int) outlineView: (NSOutlineView *)outlineView
	numberOfChildrenOfItem: (id)item
{
	if (item == nil)
	{
		return [fontFamilies count];
	}
	else if ([item isKindOfClass:[PQFontFamily class]])
	{
		return [[item members] count];
	}
	/* else */
	return 0;
}

- (id) outlineView: (NSOutlineView *)outlineView
             child: (int)index
						ofItem: (id)item
{
	if (item == nil)
	{
		return [fontFamilies objectAtIndex:index];
	}
	else if ([item isKindOfClass:[PQFontFamily class]])
	{
		return [[item members] objectAtIndex:index];
	}
	
	/* Else: something is wrong */
	return nil;
}

@end
