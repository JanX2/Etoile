/*
	PKToolbarPresentation.m

	Preferences controller subclass with preference panes listed in a toolbar

	Copyright (C) 2005 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-interent.fr>
	Date:  February 2005

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <AppKit/AppKit.h>
#ifdef GNUSTEP
#import <GNUstepGUI/GSToolbarView.h>
#endif
#import "CocoaCompatibility.h"
#import "PKPreferencesController.h"
#import "PKPrefPanesRegistry.h"
#import "PKToolbarPreferencesController.h"

extern const NSString *PKToolbarPresentationMode;

// NOTE: Hack needed for -resizePreferencesViewForView: with GNUstep
#ifdef GNUSTEP

@interface GSToolbarView (GNUstepPrivate)
- (int) _heightFromLayout;
@end

@interface NSToolbar (GNUstepPrivate)
- (GSToolbarView *) _toolbarView;
@end

#endif

@implementation PKToolbarPresentation

/*
 * Overriden methods
 */

- (void) loadUI
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    id owner = [pc owner];
    
    preferencesToolbar = 
        [[NSToolbar alloc] initWithIdentifier: @"PrefsWindowToolbar"];

	[preferencesToolbar setDelegate: self];
	[preferencesToolbar setAllowsUserCustomization: NO];
    
    if ([owner isKindOfClass: [NSWindow class]])
    {
        [(NSWindow *)owner setToolbar: preferencesToolbar];

    }
    else
    {
        NSLog(@"Preferences panes cannot be listed in a toolbar when owner is \
            not an NSWindow instance.");
        [preferencesToolbar release];
    }
    
    [super loadUI];
}

- (void) unloadUI
{
    [preferencesToolbar setVisible: NO];
    [preferencesToolbar release];
}

- (NSString *) presentationMode
{
    return (NSString *)PKToolbarPresentationMode;
}

- (NSView *) presentationView
{
    return nil;
}

- (NSView *) preferencesView
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    id owner = [pc owner];
    NSView *preferencesView = [pc preferencesView];
    
    if (preferencesView == nil && [owner isKindOfClass: [NSWindow class]])
    {
        NSView *contentView;
        
        // NOTE: With GNUstep, content view currently includes the toolbar
        // view.
        #ifdef GNUSTEP
        contentView = [owner contentViewWithoutToolbar];
        #else
        contentView = [owner contentView];
        #endif

        return contentView;
    }
    
    return preferencesView;
}

- (void) resizePreferencesViewForView: (NSView *)paneView
{
 	NSView *mainView = [self preferencesView];
    NSRect paneViewFrame = [paneView frame];
	NSRect windowFrame = [[mainView window] frame];
    int previousHeight = windowFrame.size.height;
    int heightDelta;

    #ifndef GNUSTEP

    // FIXME: Implement -frameRectForContentRect: in GNUstep 
    windowFrame.size = [[mainView window] frameRectForContentRect: paneViewFrame].size;
    
    // NOTE: We have to check carefully the view is not undersized to avoid
    // limiting switch possibilities in listed panes.
    if (windowFrame.size.height < 150)
        windowFrame.size.height = 150;
    if (windowFrame.size.width < 400)
        windowFrame.size.width = 400;
    
    /* We take in account the fact the origin is located at bottom left corner. */
    heightDelta = previousHeight - windowFrame.size.height;
    windowFrame.origin.y += heightDelta;
    
    [[mainView window] setFrame: windowFrame display: YES animate: YES];

    #else
    
    NSRect mainViewFrame = [mainView frame];
    
    /* Resize window so content area is large enough for prefs: */
    mainViewFrame.size = paneViewFrame.size;
    mainViewFrame.size.height += 
        [[preferencesToolbar _toolbarView] frame].size.height;
    mainViewFrame.origin = [[mainView window] frame].origin;
    windowFrame = [NSWindow frameRectForContentRect: mainViewFrame 
        styleMask: [[mainView window] styleMask]];
    
    // NOTE: We have to check carefully the view is not undersized to avoid
    // limiting switch possibilities in listed panes.
    if (windowFrame.size.height < 150)
        windowFrame.size.height = 150;
    if (windowFrame.size.width < 400)
        windowFrame.size.width = 400;

    // FIXME: It looks like animate option is not working well on GNUstep.
    [[mainView window] setFrame: windowFrame display: YES animate: NO];
    
    #endif
	
}

- (IBAction) switchPreferencePaneView: (id)sender
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    
    // NOTE: When -selectPreferencePaneWithIdentifier: is not the result of a
    // user click/action in toolbar, we have to update toolbar selection ourself
    // in -didSelectPreferencePaneWithIdentifier, so we set this flag.
    switchActionTriggered = YES;
    
    if ([sender isKindOfClass: [NSToolbarItem class]])
        [pc selectPreferencePaneWithIdentifier: [sender itemIdentifier]];
    
    switchActionTriggered = NO;
}

/*
 * Preferences controller delegate methods
 */

- (void) didSelectPreferencePaneWithIdentifier: (NSString *)identifier
{    
    if (switchActionTriggered == NO)
        [preferencesToolbar setSelectedItemIdentifier: identifier];
}

/*
 * Toolbar delegate methods
 */

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
      itemForItemIdentifier:(NSString*)identifier
  willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
    NSToolbarItem *toolbarItem = 
        [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];
    NSDictionary *plugin = 
        [plugins objectWithValue: identifier forKey: @"identifier"];

	[toolbarItem setLabel: [plugin objectForKey: @"name"]];
    
    /* We need to check if 'image' is not null because it can unlike 'name'. */
    if ([[plugin objectForKey: @"image"] isEqual: [NSNull null]] == NO)
        [toolbarItem setImage: [plugin objectForKey: @"image"]];
	
    [toolbarItem setTarget: self];
    [toolbarItem setAction: @selector(switchPreferencePaneView:)];
    
	return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar 
{
    return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar 
{
    NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];
    NSArray *identifiers = [plugins valueForKey: @"identifier"];
    
    return identifiers;
}

- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar 
{
	return [self toolbarAllowedItemIdentifiers: toolbar];
}

@end
