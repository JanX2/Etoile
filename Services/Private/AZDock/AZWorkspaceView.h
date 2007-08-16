#import <AppKit/AppKit.h>
#import "AZDockView.h"

#ifdef USE_BOOKMARK
@class BKBookmarkStore;
#endif

/* To display on AZDock's icon window and serves as workspace switcher */
@interface AZWorkspaceView: AZDockView 
{
  /* Cache */
  NSArray *names;
  int number_workspace, current_workspace;

  NSMenu *workspaceMenu;
#ifdef USE_BOOKMARK
  NSMenu *applicationMenu;
  BKBookmarkStore *appStore;
#endif
}

- (void) setCurrentWorkspace: (int) workspace;
- (void) setNumberOfWorkspaces: (int) number;
- (void) setWorkspaceNames: (NSArray *) names;

#ifdef USE_BOOKMARK
/* Not retained */
- (void) setApplicationBookmarkStore: (BKBookmarkStore *) store;
#endif

@end

