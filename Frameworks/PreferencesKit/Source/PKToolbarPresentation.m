/*
	PKToolbarPresentation.m

	Preferences controller subclass with preference panes listed in a toolbar

	Copyright (C) 2005 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
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
#import "PKToolbarPresentation.h"
#import "GNUstep.h"

const NSString *PKToolbarPresentationMode = @"PKToolbarPresentationMode";


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

/* Dependency injection relying on -load method being sent to superclass before
   subclasses. It means we can be sure PKPresentationBuilder is already loaded
   by runtime, when each subclass receives this message. */
+ (void) load
{
  [super inject: self forKey: PKToolbarPresentationMode];
}

/*
 * Overriden methods
 */

- (void) loadUI
{
  id owner = [preferencesController owner];
    
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
  id owner = [preferencesController owner];
    
  // FIXME: this line is not needed, but we keep it because it outlines a bug
  // in GSToolbar; toolbar view is not removed properly from the views
  // hierarchy when the window toolbar is set to nil consecutively to the
  // method call on the next line.
  //[preferencesToolbar setVisible: NO];
 
  // NOTE: -[toolbar release] shouldn't be used because it doesn't clean
  // everything (like validation objects). We should document this point in
  // GSToolbar.
  [(NSWindow *)owner setToolbar: nil];
}

- (NSString *) presentationMode
{
    return (NSString *)PKToolbarPresentationMode;
}

- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
  NSView *mainView = [preferencesController preferencesView];
  NSRect paneViewFrame = [paneView frame];
  NSRect windowFrame = [[mainView window] frame];
    
  [super layoutPreferencesViewWithPaneView: paneView];

  #ifndef GNUSTEP
  NSRect oldFrame = [[mainView window] frame];
  // FIXME: Implement -frameRectForContentRect: in GNUstep 
  windowFrame.size = [[mainView window] frameRectForContentRect: paneViewFrame].size;
    
  // NOTE: We have to check carefully the view is not undersized to avoid
  // limiting switch possibilities in listed panes.
  if (windowFrame.size.height < 150)
    windowFrame.size.height = 150;
  if (windowFrame.size.width < 400)
    windowFrame.size.width = 400;
  
  windowFrame.origin.y -= (windowFrame.size.height-oldFrame.size.height);
   
  /* We take in account the fact the origin is located at bottom left corner. */
    
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
  // NOTE: When -selectPreferencePaneWithIdentifier: is not the result of a
  // user click/action in toolbar, we have to update toolbar selection ourself
  // in -didSelectPreferencePaneWithIdentifier, so we set this flag.
  switchActionTriggered = YES;
    
  if ([sender isKindOfClass: [NSToolbarItem class]])
      [preferencesController selectPreferencePaneWithIdentifier: [sender itemIdentifier]];
    
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
    NSDictionary *plugin = 
        [allLoadedPlugins objectWithValue: identifier forKey: @"identifier"];

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
  return [allLoadedPlugins valueForKey: @"identifier"];
}

- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar 
{
  return [self toolbarAllowedItemIdentifiers: toolbar];
}

@end
