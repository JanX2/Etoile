/*
	PKPopUpButtonPresentation.m
 
	Preferences controller subclass with preference panes listed in a popup button
 
	Copyright (C) 2005-2007 Yen-Ju Chen, Quentin Mathe    
 
	Author:  Yen-Ju Chen <yjchenx gmail>
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2005
 
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
#import <PaneKit/CocoaCompatibility.h>
#import <PaneKit/PKPanesController.h>
#import <PaneKit/PKPaneRegistry.h>
#import <PaneKit/PKPopUpButtonPresentation.h>
#import "GNUstep.h"

const NSString *PKPopUpPresentationMode = @"PKPopUpPresentationMode";

#define BUTTON_HEIGHT 25 
#define PAD 5

@implementation PKPopUpButtonPresentation

/* Dependency injection relying on -load method being sent to superclass before
   subclasses. It means we can be sure PKPresentationBuilder is already loaded
   by runtime, when each subclass receives this message. */
+ (void) load
{
  [PKPresentationBuilder inject: self forKey: PKPopUpPresentationMode];
}

/*
 * Overriden methods
 */

- (id) init
{
  self = [super init];

  /* We build the table here and reuse it */
  NSRect rect = NSMakeRect(0, 0, 50, BUTTON_HEIGHT);
  popUpButton = [[NSPopUpButton alloc] initWithFrame: rect];
  [popUpButton setAutoresizingMask: NSViewWidthSizable|NSViewMinYMargin];
  [popUpButton setTarget: self];
  [popUpButton setAction: @selector(popUpButtonAction:)];

  return self;
}

- (void) loadUI
{
  NSView *mainViewContainer = [controller view];
  NSRect frame = [[controller view] frame];
    
  [popUpButton setFrame: NSMakeRect(PAD, frame.size.height-PAD-BUTTON_HEIGHT,
                                    frame.size.width-2*PAD, BUTTON_HEIGHT)];
  int i, count = [allLoadedPlugins count];
  for (i = 0; i < count; i++)
  {
    NSDictionary *info = [allLoadedPlugins objectAtIndex: i];
    [popUpButton addItemWithTitle: [info objectForKey: @"name"]];
  }
  [popUpButton selectItemAtIndex: 0];
    
  [mainViewContainer addSubview: popUpButton];
    
  [super loadUI];
}

- (void) unloadUI
{
  [popUpButton removeFromSuperview];
}

- (NSString *) presentationMode
{
  return (NSString *)PKPopUpPresentationMode;
}

/* It is too complicated to call super because each presentation has
   different architecture. So we need to add paneView ourselves.
   And over-use -setFrame causes view to flick. */
- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
  if (paneView == nil)
    return;

  NSView *mainView = [controller view];
  NSRect paneFrame = [paneView frame];
  NSRect popUpFrame = [popUpButton frame];
  NSRect windowFrame = [[mainView window] frame];
  NSRect contentFrame = NSZeroRect;
  int previousHeight = windowFrame.size.height;
  int heightDelta;

  /* Resize window so content area is large enough for prefs. */
    
  popUpFrame.size.width = paneFrame.size.width-2*PAD;
  paneFrame.origin.x = 0;
  paneFrame.origin.y = 0;
  
  contentFrame.size.width = windowFrame.size.width;
  contentFrame.size.height = 2*PAD+BUTTON_HEIGHT+paneFrame.size.height;
   
  // FIXME: Implement -frameRectForContentRect: in GNUstep 
  windowFrame.size = [NSWindow frameRectForContentRect: contentFrame
      styleMask: [[mainView window] styleMask]].size;
    
  // NOTE: We have to check carefully the view is not undersized to avoid
  // limiting switch possibilities in listed panes.
  if (windowFrame.size.height < 100)
      windowFrame.size.height = 100;
  if (windowFrame.size.width < 100)
      windowFrame.size.width = 100;
    
  /* We take in account the fact the origin is located at bottom left corner. */
  heightDelta = previousHeight - windowFrame.size.height;
  windowFrame.origin.y += heightDelta;
    
  // FIXME: Animated resizing is buggy on GNUstep (exception thrown about
  // periodic events already generated for the current thread)
  #ifndef GNUSTEP
    [[mainView window] setFrame: windowFrame display: YES animate: YES];
  #else
    [[mainView window] setFrame: windowFrame display: YES animate: NO];
  #endif

  /* Do not resize table view because it is autoresizable.
   * Resize paneView before adding it into window to reduce flick.
   * It is also the reason that adding it after window is resized.
   */
  [paneView setFrame: paneFrame];
  if ([[paneView superview] isEqual: mainView] == NO)
    [mainView addSubview: paneView];
}

- (void) switchPaneView: (id)sender
{
  int row = [popUpButton indexOfSelectedItem];
  NSString *path = [[allLoadedPlugins objectAtIndex: row] objectForKey: @"identifier"];
    
  [controller selectPaneWithIdentifier: path];
}

- (void) popUpButtonAction: (id) sender
{
  [self switchPaneView: sender];
#if 0
  int row = [preferencesTableView selectedRow];
  NSString *path = (NSString *)[[allLoadedPlugins objectAtIndex: row] objectForKey: @"path"];
	
  [controller updateUIForPane: [[controller registry] paneAtPath: path]];
#endif
}

/*
 * Preferences controller delegate methods
 */

- (void) didSelectPaneWithIdentifier: (NSString *)identifier
{    
  NSDictionary *info = [allLoadedPlugins objectWithValue: identifier 
                                         forKey: @"identifier"];
  int row = [allLoadedPlugins indexOfObject: info];
  if (row != NSNotFound)
    [popUpButton selectItemAtIndex: row];
}

@end
