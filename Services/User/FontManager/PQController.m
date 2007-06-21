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

	while ((currentName = [familyNamesEnum nextObject]))
	{
		NSArray *members = [fontManager availableMembersOfFontFamily: currentName];

		NSMutableArray *newMembers = [[NSMutableArray alloc] init];
		NSArray *currentMember;
		NSEnumerator *membersEnum = [members objectEnumerator];

		while ((currentMember = [membersEnum nextObject]))
		{
			[newMembers addObject:[currentMember objectAtIndex:0]];
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
	[self updateSample];


	/* Values that should be set in MainMenu.gorm, but aren't */
	NSTableColumn * fontListColumn = [[[fontList tableColumns] 
objectAtIndex: 0] headerCell];
	[fontListColumn setTitle: @"Fonts"];
	[fontListColumn setEditable: NO];
	[[[[groupList tableColumns] objectAtIndex: 0] headerCell] setTitle: @"Groups"];

	[fontList sizeLastColumnToFit];
	[groupList sizeLastColumnToFit];


	int fontsCount = [fontFamilies count];

	if (fontsCount < 2)
	{
		[fontsInfoField setStringValue:
			[NSString stringWithFormat:@"%i %@", fontsCount,
			                           NSLocalizedString(@"PQFamily", nil)]];
	}
	else
	{
		[fontsInfoField setStringValue:
			[NSString stringWithFormat:@"%i %@", fontsCount,
			                           NSLocalizedString(@"PQFamilies", nil)]];
	}
}

/* Groups [table] view data source code */

- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
	return 1; // Temp
}

- (id) tableView: (NSTableView *)aTableView
	objectValueForTableColumn: (NSTableColumn *)aTableColumn
	           row: (int)rowIndex
{
	return @"All"; // Temp
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
		NSMutableString *styleName = [[NSMutableString alloc] init];
		
		[styleName setString: [[NSFont fontWithName: item size: 0.0] displayName]];
		
		NSRange familyName = [styleName
			rangeOfString: [[NSFont fontWithName: item size: 0.0] familyName]];

		if (familyName.location != NSNotFound)
		{
			[styleName deleteCharactersInRange:familyName];

			[styleName setString: [styleName stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceCharacterSet]]];
		}

		if ([styleName isEqualToString:@""])
		{
			return @"Regular";
		}
		/* else */
		return styleName;
	}
	
	/* Else: something is wrong */
	return nil;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	if (item == nil) /* Is this even necessary? */
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

/* Watch for selection changes */

- (void) tableViewSelectionDidChange: (NSNotification *)aNotification
{
	// Until we implement groups.
}

- (void) outlineViewSelectionDidChange: (NSNotification *)notification
{
	[self updateSample];
}

- (void) updateSample
{
	// NOTE: This method probably could be better.
	NSIndexSet *selectedRows = [fontList selectedRowIndexes];
	
	NSEnumerator *itemEnum = [fontFamilies objectEnumerator];
	PQFontFamily *currentItem;
	
	NSMutableArray *selectedItems = [[NSMutableArray alloc] init];
	
	while ((currentItem = [itemEnum nextObject]))
	{
    if ([selectedRows containsIndex:[fontList rowForItem:currentItem]])
		{
			[selectedItems addObjectsFromArray:[currentItem members]];
		}
		else
		{
			NSEnumerator *membersEnum = [[currentItem members] objectEnumerator];
			NSString *currentMember;
			
			while ((currentMember = [membersEnum nextObject]))
			{
				if ([selectedRows containsIndex:[fontList rowForItem:currentMember]])
				{
					[selectedItems addObject:currentMember];
				}
			}
		}
		/* Else: something is wrong */
	}
	
	[sampleController setFonts:selectedItems];
}

- (void) dealloc
{
	RELEASE(fontFamilies);
	
	[super dealloc];
}

@end
