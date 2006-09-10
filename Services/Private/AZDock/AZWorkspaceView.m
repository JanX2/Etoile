#import "AZWorkspaceView.h"
#import <XWindowServerKit/XScreen.h>

@implementation AZWorkspaceView

- (void) workspaceDidChanged: (NSNotification *) not
{
  NSLog(@"%@", not);
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

  [[NSDistributedNotificationCenter defaultCenter] 
	  addObserver: self
	  selector: @selector(workspaceDidChanged:)
	  name: XCurrentWorkspaceDidChangeNotification
	  object: nil];

  return self;
}

- (void) dealloc
{
  [super dealloc];
}

@end
