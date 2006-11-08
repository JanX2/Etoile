/*
	PKTableViewPresentation.m
 
	Preferences controller subclass with preference panes listed in a table bview
 
	Copyright (C) 2005 Quentin Mathe    
 
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
#import <PaneKit/PKPreferencesController.h>
#import <PaneKit/PKPrefPanesRegistry.h>
#import <PaneKit/PKTableViewPresentation.h>
#import "GNUstep.h"

const NSString *PKTablePresentationMode = @"PKTablePresentationMode";


@implementation PKTableViewPresentation

/* Dependency injection relying on -load method being sent to superclass before
   subclasses. It means we can be sure PKPresentationBuilder is already loaded
   by runtime, when each subclass receives this message. */
+ (void) load
{
  [super inject: self forKey: PKTablePresentationMode];
}

/*
 * Overriden methods
 */

- (void) loadUI
{
  NSView *mainViewContainer = [preferencesController preferencesView];
    
#if 0
    /* We use a completely prebuilt table view we retrieve in a dedicated gorm file
       to avoid the nightmare to set up it manually in code with every elements it
       includes like corner view, scroll view etc. */
    
    BOOL nibLoaded = [NSBundle loadNibNamed: @"PrebuiltTableView" owner: self];
    
    if (nibLoaded == NO)
        [NSException raise: @"PKTableViewPresentationException"
            format: @"Impossible to load PrebuiltTableView nib"];
    
    if (prebuiltTableView == nil)
        [NSException raise: @"PKTableViewPresentationException"
            format: @"PrebuiltTableView is nil"];

    [prebuiltTableView removeFromSuperview];
#else
  NSRect rect = NSMakeRect(0, 0, 180, [mainViewContainer frame].size.height);
  prebuiltTableView = [[NSScrollView alloc] initWithFrame: rect];
  [prebuiltTableView setAutoresizingMask: NSViewHeightSizable];

  NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: @"name"];
  [column setWidth: 180];
  [column setEditable: NO];

  rect = [[prebuiltTableView documentView] bounds];
  preferencesTableView = [[NSTableView alloc] initWithFrame: rect];
  [preferencesTableView setAutoresizingMask: NSViewHeightSizable];
  [preferencesTableView addTableColumn: column];
  [prebuiltTableView setDocumentView: preferencesTableView];
  DESTROY(column);
  RELEASE(preferencesTableView);
  AUTORELEASE(prebuiltTableView);
#endif
    
#if 0 
  [prebuiltTableView setFrameSize: NSMakeSize(180, [mainViewContainer frame].size.height)];
  [prebuiltTableView setFrameOrigin: NSMakePoint(0, 0)];
#endif
  [mainViewContainer addSubview: prebuiltTableView];
    
  /* Finish table view specific set up. */
  // NOTE: the next two lines are needed only with Gorm because it doesn't
  // support to disable column headers.
  [preferencesTableView setCornerView: nil];
  [preferencesTableView setHeaderView: nil];
  [preferencesTableView setDataSource: self];
  [preferencesTableView setDelegate: self];
  [preferencesTableView reloadData];
    
  [super loadUI];
}

- (void) unloadUI
{
  [prebuiltTableView removeFromSuperview];
}

- (NSString *) presentationMode
{
  return (NSString *)PKTablePresentationMode;
}

/* It is too complicated to call super because each presentation has
   different architecture. So we need to add paneView ourselves.
   And over-use -setFrame causes view to flick. */
- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
  if (paneView == nil)
    return;

  NSView *mainView = [preferencesController preferencesView];
  NSRect paneFrame = [paneView frame];
  NSRect tableFrame = [prebuiltTableView frame];
  NSRect windowFrame = [[mainView window] frame];
  NSRect contentFrame = NSZeroRect;
  int previousHeight = windowFrame.size.height;
  int heightDelta;

  /* Resize window so content area is large enough for prefs. */
    
  tableFrame.size.height = paneFrame.size.height;
  paneFrame.origin.x = tableFrame.size.width;
  paneFrame.origin.y = 0;
  
  contentFrame.size.width = tableFrame.size.width + paneFrame.size.width;
  contentFrame.size.height = paneFrame.size.height;
   
  // FIXME: Implement -frameRectForContentRect: in GNUstep 
  windowFrame.size = [NSWindow frameRectForContentRect: contentFrame
      styleMask: [[mainView window] styleMask]].size;
    
  // NOTE: We have to check carefully the view is not undersized to avoid
  // limiting switch possibilities in listed panes.
  if (windowFrame.size.height < 150)
      windowFrame.size.height = 150;
  if (windowFrame.size.width < 400)
      windowFrame.size.width = 400;
    
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

- (IBAction) switchPreferencePaneView: (id)sender
{
  int row = [preferencesTableView selectedRow];
  NSString *path = [[allLoadedPlugins objectAtIndex: row] identifier];
    
  [preferencesController selectPreferencePaneWithIdentifier: path];
}

/*
 * Preferences controller delegate methods
 */

- (void) didSelectPreferencePaneWithIdentifier: (NSString *)identifier
{    
  NSDictionary *info = [allLoadedPlugins objectWithValue: identifier 
                                         forKey: @"identifier"];
  int row = [allLoadedPlugins indexOfObject: info];
    
  [preferencesTableView selectRow: row byExtendingSelection: NO];
}

/*
 * Table view delegate methods
 */

- (int) numberOfRowsInTableView: (NSTableView *)tableView
{
  return [allLoadedPlugins count];
}


- (id) tableView: (NSTableView*)tableView 
       objectValueForTableColumn: (NSTableColumn *) tableColumn 
       row: (int)row
{
  NSDictionary *info = [allLoadedPlugins objectAtIndex: row];
  return [info objectForKey: @"name"];
}


- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
  int row = [preferencesTableView selectedRow];
  NSString *path = (NSString *)[[allLoadedPlugins objectAtIndex: row] objectForKey: @"path"];
	
  [preferencesController updateUIForPreferencePane: [[PKPrefPanesRegistry sharedRegistry] preferencePaneAtPath: path]];
}

@end
