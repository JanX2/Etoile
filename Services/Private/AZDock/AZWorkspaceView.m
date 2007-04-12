#import "AZWorkspaceView.h"
#import <XWindowServerKit/XScreen.h>
#import <BookmarkKit/BookmarkKit.h>

@interface AZWorkspaceView (AZPrivate)
- (void) updateWorkspaceMenu;
@end

@implementation AZWorkspaceView

/** Private **/
- (void) workspaceAction: (id) sender
{
  int index = [workspaceMenu indexOfItem: sender];
  [[[self window] screen] setCurrentWorkspace: index];
  /* Update state */
  int i;
  for (i = 0; i < number_workspace; i++) {
    if (i == index) {
      [[workspaceMenu itemAtIndex: i] setState: NSOnState];
    } else {
      [[workspaceMenu itemAtIndex: i] setState: NSOffState];
    }
  }
}

- (void) updateWorkspaceMenu
{
  int i, menu_count = [workspaceMenu numberOfItems];
  NSString *title;
  for (i = 0; i < number_workspace; i++) {
    if (i < [names count]) {
      title = [names objectAtIndex: i];
    } else {
      title = [NSString stringWithFormat: _(@"Workspace %d"), i+1];
    }

    if (i < menu_count) {
      [[workspaceMenu itemAtIndex: i] setTitle: title];
    } else {
      [workspaceMenu addItemWithTitle: title
	             action: @selector(workspaceAction:)
		     keyEquivalent: nil];
    }
    [[workspaceMenu itemAtIndex: i] setTarget: self];
    if (i == current_workspace) {
      [[workspaceMenu itemAtIndex: i] setState: NSOnState];
    } else {
      [[workspaceMenu itemAtIndex: i] setState: NSOffState];
    }
  }
  for (i = menu_count-1; i >= number_workspace; i--) {
    [workspaceMenu removeItemAtIndex: i];
  }
}

- (void) applicationAction: (id) sender
{
  int index = [applicationMenu indexOfItem: sender];
  NSArray *items = [appStore topLevelRecords];
  if ((index > -1) && (index < [items count])) {
    NSString *path = [[[items objectAtIndex: index] URL] path];
    BOOL success = [[NSWorkspace sharedWorkspace] launchApplication: path];
    if (success == NO) {
      /* Try regular execute */
      [NSTask launchedTaskWithLaunchPath: path arguments: nil];
    }
  }
}

- (void) updateApplicationMenu
{
  int i, menu_count = [applicationMenu numberOfItems];
  NSArray *items = [appStore topLevelRecords];
  int numberOfItems = [items count];
  NSString *title;
  for (i = 0; i < numberOfItems; i++) {
    title = [[[[items objectAtIndex: i] URL] path] lastPathComponent];

    if (i < menu_count) {
      [[applicationMenu itemAtIndex: i] setTitle: title];
    } else {
      [applicationMenu addItemWithTitle: title
	             action: @selector(applicationAction:)
		     keyEquivalent: nil];
    }
    [[applicationMenu itemAtIndex: i] setTarget: self];
  }
  for (i = menu_count-1; i >= numberOfItems; i--) {
    [applicationMenu removeItemAtIndex: i];
  }
}

- (void) bookmarkChanged: (NSNotification *) not
{
  if ([[not userInfo] objectForKey: CKCollectionNotificationKey] == appStore) {
    [self updateApplicationMenu];
  }
}

/** End of private **/

- (void) setCurrentWorkspace: (int) workspace
{
  current_workspace = workspace;
  [self updateWorkspaceMenu];
}

- (void) setNumberOfWorkspaces: (int) number
{
  number_workspace = number;
  [self updateWorkspaceMenu];
}

- (void) setWorkspaceNames: (NSArray *) n
{
  ASSIGN(names, n);
  [self updateWorkspaceMenu];
}

- (void) setApplicationBookmarkStore: (BKBookmarkStore *) store
{
  appStore = store;
  [self updateApplicationMenu];
}

- (void) mouseUp: (NSEvent *) event
{
  if ([event type] == NSLeftMouseUp) {
    /* Make sure the mouse is released inside the window */
    NSPoint p = [event locationInWindow];
    if (NSPointInRect(p, [self bounds]) == NO) {
      return;
    }

    BOOL success = NO;
    /* Open the GSWorkspaceApplication */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *application = [defaults stringForKey: @"GSWorkspaceApplication"];
    if (application == nil) {
      /* Get from NSGlobalDomain */
      application = [[defaults persistentDomainForName: @"NSGlobalDomainName"] objectForKey: @"GSWorkspaceApplication"];
      if (application == nil) {
        application = @"GWorkspace";
      }
    }
    if (application) {
      success = [[NSWorkspace sharedWorkspace] launchApplication: application];
    } 
    if (success == NO) {
      /* Open xterm by default */
      [NSTask launchedTaskWithLaunchPath: @"xterm" arguments: nil];
    }
  } else {
    [super mouseUp: event];
  }
}

- (id) initWithFrame: (NSRect) rect
{
  self = [super initWithFrame: rect];
  ASSIGN(image, [NSImage imageNamed: @"Etoile.tiff"]);
  /* Remove all default menu */
  while (([contextualMenu numberOfItems])) {
    [contextualMenu removeItemAtIndex: 0];
  }
  id <NSMenuItem> item = [contextualMenu addItemWithTitle: _(@"Workspace")
	                                       action: NULL
		                       keyEquivalent: NULL];
  workspaceMenu = [[NSMenu alloc] initWithTitle: _(@"Workspace")];
  [contextualMenu setSubmenu: workspaceMenu forItem: item];
  RELEASE(workspaceMenu);

  item = [contextualMenu addItemWithTitle: _(@"Recent Applications")
	                        action: NULL
				keyEquivalent: NULL];

  applicationMenu = [[NSMenu alloc] initWithTitle: _(@"Recent Applications")];
  [contextualMenu setSubmenu: applicationMenu forItem: item];
  RELEASE(applicationMenu);

  [contextualMenu addItemWithTitle: _(@"Quit")
                            action: @selector(terminate:)
                     keyEquivalent: NULL];

  /* Listen to recent applications change */
  [[NSNotificationCenter defaultCenter]
	  addObserver: self
	  selector: @selector(bookmarkChanged:)
	  name: CKCollectionChangedNotification
	  object: nil];

  return self;
}

- (void) dealloc
{
  DESTROY(names);
  [super dealloc];
}

@end
