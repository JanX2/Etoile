#import "AZWorkspaceView.h"
#import <XWindowServerKit/XScreen.h>

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


- (void) mouseDown: (NSEvent *) event
{
  if ([event type] == NSLeftMouseDown) {
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
    [super mouseDown: event];
  }
}

- (id) initWithFrame: (NSRect) rect
{
  self = [super initWithFrame: rect];
  ASSIGN(image, [NSImage imageNamed: @"GNUstep.tiff"]);
  /* Remove all default menu */
  while (([contextualMenu numberOfItems])) {
    [contextualMenu removeItemAtIndex: 0];
  }
  NSMenuItem *item = [contextualMenu addItemWithTitle: @"Workspace"
	                                       action: NULL
		                       keyEquivalent: NULL];
  workspaceMenu = [[NSMenu alloc] initWithTitle: @"Workspace"];
  [contextualMenu setSubmenu: workspaceMenu forItem: item];
  RELEASE(workspaceMenu);

  return self;
}

- (void) dealloc
{
  DESTROY(names);
  [super dealloc];
}

@end
