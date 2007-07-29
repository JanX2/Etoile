//
//  NewPreferencesController.m
//  Vienna
//
//  Created by Steve on 10/15/05.
//  Copyright (c) 2007 Yen-Ju Chen. All rights reserved.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NewPreferencesController.h"

@interface NewPreferencesController (Private)
	-(void)selectPane:(NSString *)identifier;
@end

@interface NSToolbar (NSToolbarPrivate)
	-(NSView *)_toolbarView;
@end

@implementation NewPreferencesController

/* init
 * Initialises a new instance of the new PreferencesController object.
 */
-(id)init
{
	NSRect rect = NSMakeRect(200, 200, 360, 240);
	NSWindow * win = [[NSWindow alloc] initWithContentRect: rect
	                     styleMask: NSTitledWindowMask |
                                    NSClosableWindowMask
	                       backing: NSBackingStoreBuffered
	                         defer: NO];
	[win setFrameAutosaveName: @"newPreferencesWindow"];
	[win setDelegate: self];
	[win setReleasedWhenClosed: NO];
	if ((self = [super initWithWindow: [win autorelease]]) != nil)
	{
		prefsDict = nil;
		prefPanes = nil;
		prefsIdentifiers = nil;
		selectedIdentifier = nil;
		[self awakeFromNib];
	}
	return self;
}

/* awakeFromNib
 * Do the things that only make sense after the window file is loaded.
 */
-(void)awakeFromNib
{
	static BOOL isPrimaryNib = YES;
	
	// We get called for all view NIBs, so don't handle those or we'll stack overflow.
	if (!isPrimaryNib)
		return;
	
	// Load the NIBs using the plist to locate them and build the prefIdentifiersArray
	// array of identifiers.
	NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
	NSString * pathToPList = [thisBundle pathForResource:@"Preferences.plist" ofType:@""];
	NSAssert(pathToPList != nil, @"Missing Preferences.plist in build");

	// Load the dictionary and sort the keys by name to create the ordered
	// identifiers for each pane.
	prefsDict = [[NSDictionary dictionaryWithContentsOfFile:pathToPList] retain];
	prefsIdentifiers = [[[prefsDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
	NSAssert([prefsIdentifiers count] > 0, @"Empty Preferences.plist file");

	// Set the title
	[[self window] setTitle:NSLocalizedString(@"Preferences", nil)];

#ifndef GNUSTEP
	// Hide the toolbar pill button
	[[[self window] standardWindowButton:NSWindowToolbarButton] setFrame:NSZeroRect];
#endif

	// Create an empty view
	blankView = [[NSView alloc] initWithFrame:[[[self window] contentView] frame]];
	
	// Array of pane objects
	prefPanes = [[NSMutableDictionary alloc] init];
	
	// Center the window
	[[self window] center];
	
	// Primary NIB is done.
	isPrimaryNib = NO;
	
	// Select the first pane
	[self selectPane:[prefsIdentifiers objectAtIndex:0]];

	// Create the toolbar
	NSToolbar * toolbar = [[NSToolbar alloc] initWithIdentifier:@"PrefsToolbar"];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setDelegate:self];
	[[self window] setToolbar:toolbar];
}

/* itemForItemIdentifier
 * Creates and returns an NSToolbarItem for the specified identifier.
 */
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem * newItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	NSDictionary * prefsItem = [prefsDict objectForKey:itemIdentifier];
	[newItem setLabel:NSLocalizedString([prefsItem valueForKey:@"Title"], nil)];
	[newItem setTarget:self];
	[newItem setAction:@selector(prefsPaneSelection:)];
	
	NSString * prefImage = [prefsItem valueForKey:@"Image"];
	if (prefImage != nil)
		[newItem setImage:[NSImage imageNamed:prefImage]];
	return newItem;
}

/* prefsPaneSelection
 * Change the preference pane.
 */
-(IBAction)prefsPaneSelection:(id)sender
{
	NSToolbar * toolbar = [[self window] toolbar];
	[self selectPane:[toolbar selectedItemIdentifier]];
}

/* selectPane
 * Activate the preference pane with the given identifier. Resize the main
 * window to accommodate the pane contents.
 */
-(void)selectPane:(NSString *)identifier
{	
	NSDictionary * prefItem = [prefsDict objectForKey:identifier];
	NSAssert(prefItem != nil, @"Not a valid preference identifier");

	// Skip if we're already the selected pane
	if ([identifier isEqualToString:selectedIdentifier])
		return;
	
	// Make sure the associated class has been instantiated
	id prefPane = [prefPanes objectForKey:identifier];
	if (prefPane == nil)
	{
		NSString * className = [prefItem objectForKey:@"ClassName"];
		if (className == nil)
		{
			NSLog(@"Missing ClassName attribute from preference %@", identifier);
			return;
		}
		Class classObject = NSClassFromString(className);
		if (classObject == nil)
		{
			NSLog(@"Cannot find class '%@' in preference %@", className, identifier);
			return;
		}
		prefPane = [[classObject alloc] init];
		if (prefPane == nil)
			return;

		// This is the only safe time to add the pane to the array
		[prefPanes setObject:prefPane forKey:identifier];
		[prefPane release];
	}

	// If we get this far, OK to select the new item. Otherwise we're staying
	// on the old one.
	NSToolbar * toolbar = [[self window] toolbar];
	[toolbar setSelectedItemIdentifier:identifier];

	if (currentView)
	{
		[currentView removeFromSuperview];
		currentView = nil;
	}

	currentView = [[[prefPane window] contentView] retain];

	// Compute the new frame window height and width
	NSRect windowFrame = [NSWindow contentRectForFrameRect:[[self window] frame] styleMask:[[self window] styleMask]];

	float newWindowHeight = NSHeight([currentView frame]) + NSHeight([[toolbar _toolbarView] frame]);
	float newWindowWidth = NSWidth([currentView frame]);

	NSRect newFrameRect = NSMakeRect(NSMinX(windowFrame), NSMaxY(windowFrame) - newWindowHeight, newWindowWidth, newWindowHeight);
	NSRect newWindowFrame = [NSWindow frameRectForContentRect:newFrameRect styleMask:[[self window] styleMask]];
	[[self window] setFrame:newWindowFrame display:YES animate:[[self window] isVisible]];
	[[[self window] contentView] addSubview: currentView];

	// Remember this pane identifier.
	[selectedIdentifier release];
	selectedIdentifier = [identifier retain];
}

/* validateToolbarItem
 * Every single toolbar item should be enabled.
 */
-(BOOL)validateToolbarItem:(NSToolbarItem*)toolbarItem
{
	return YES;
}

/* toolbarAllowedItemIdentifiers
 * The allowed toolbar items. These are all preference items.
 */
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return prefsIdentifiers;
}

/* toolbarSelectableItemIdentifiers
 * All the selectable toolbar items. This is everything, as usual.
 */
-(NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return prefsIdentifiers;
}

/* toolbarDefaultItemIdentifiers
 * The default toolbar items. These are all preference items.
 */
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return prefsIdentifiers;
}

/* dealloc
 * Clean up behind ourselves.
 */
-(void)dealloc
{
	[selectedIdentifier release];
	[blankView release];
	[prefPanes release];
	[prefsIdentifiers release];
	[prefsDict release];
	[super dealloc];
}
@end
