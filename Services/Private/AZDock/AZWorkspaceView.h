#import <AppKit/AppKit.h>
#import "AZDockView.h"

@class BKBookmarkStore;

/* To display on AZDock's icon window and serves as workspace switcher */
@interface AZWorkspaceView: AZDockView 
{
  /* Cache */
  NSArray *names;
  int number_workspace, current_workspace;

  NSMenu *workspaceMenu;
  NSMenu *applicationMenu;
  BKBookmarkStore *appStore;
}

- (void) setCurrentWorkspace: (int) workspace;
- (void) setNumberOfWorkspaces: (int) number;
- (void) setWorkspaceNames: (NSArray *) names;

/* Not retained */
- (void) setApplicationBookmarkStore: (BKBookmarkStore *) store;

@end

