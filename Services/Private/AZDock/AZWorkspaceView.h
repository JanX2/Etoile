#import <AppKit/AppKit.h>
#import "AZDockView.h"

/* To display on AZDock's icon window and serves as workspace switcher */
@interface AZWorkspaceView: AZDockView 
{
  /* Cache */
  NSArray *names;
  int number_workspace, current_workspace;
}

- (void) setCurrentWorkspace: (int) workspace;
- (void) setNumberOfWorkspaces: (int) number;
- (void) setWorkspaceNames: (NSArray *) names;

@end

