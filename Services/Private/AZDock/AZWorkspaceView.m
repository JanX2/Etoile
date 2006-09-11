#import "AZWorkspaceView.h"
#import <XWindowServerKit/XScreen.h>

@implementation AZWorkspaceView

/** Private **/
- (void) workspaceAction: (id) sender
{
  int index = [contextualMenu indexOfItem: sender];
  [[[self window] screen] setCurrentWorkspace: index];
}

- (void) updateContextualMenu
{
  int i, menu_count = [contextualMenu numberOfItems];
  NSString *title;
  for (i = 0; i < number_workspace; i++) {
    if (i < [names count]) {
      title = [names objectAtIndex: i];
    } else {
      title = [NSString stringWithFormat: _(@"Workspace %d"), i+1];
    }

    if (i < menu_count) {
      [[contextualMenu itemAtIndex: i] setTitle: title];
    } else {
      [contextualMenu addItemWithTitle: title
	             action: @selector(workspaceAction:)
		     keyEquivalent: nil];
    }
    [[contextualMenu itemAtIndex: i] setTarget: self];
    if (i == current_workspace) {
      [[contextualMenu itemAtIndex: i] setState: NSOnState];
    } else {
      [[contextualMenu itemAtIndex: i] setState: NSOffState];
    }
  }
  for (i = menu_count-1; i >= number_workspace; i--) {
    [contextualMenu removeItemAtIndex: i];
  }
}

/** End of private **/

- (void) setCurrentWorkspace: (int) workspace
{
  current_workspace = workspace;
  [self updateContextualMenu];
}

- (void) setNumberOfWorkspaces: (int) number
{
  number_workspace = number;
  [self updateContextualMenu];
}

- (void) setWorkspaceNames: (NSArray *) n
{
  ASSIGN(names, n);
  [self updateContextualMenu];
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
  return self;
}

- (void) dealloc
{
  DESTROY(names);
  [super dealloc];
}

@end
