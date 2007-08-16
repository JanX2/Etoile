#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>
#import <AZDockApp.h>

@class XWindow;
@class AZWorkspaceView;
#ifdef USE_BOOKMARK
@class BKBookmarkStore;
#endif

@interface AZDock: NSObject
{
	GSDisplayServer *server;
	Display *dpy;
	int screen;
	Window root_win;

	NSMutableArray *apps; // application to display;
	NSMutableArray *blacklist; // application to ignore.

	/* Replace default gnustep icon window */
	XWindow *iconWindow;
	AZWorkspaceView *workspaceView;
	AZDockPosition position;
	BOOL isHidden;
	BOOL autoHidden;
	NSRect dockFrame;
	int maxApps;

#ifdef USE_BOOKMARK
	BKBookmarkStore *store;
#endif
	NSWorkspace *workspace;

	Atom X_NET_CURRENT_DESKTOP;
	Atom X_NET_NUMBER_OF_DESKTOPS;
	Atom X_NET_DESKTOP_NAMES;
	Atom X_NET_CLIENT_LIST;
	Atom X_NET_WM_STATE_SKIP_PAGER;
	Atom X_NET_WM_STATE_SKIP_TASKBAR;
}

+ (AZDock *) sharedDock;

#ifdef USE_BOOKMARK
- (void) addBookmark: (AZDockApp *) app;
#endif
- (void) organizeApplications;
- (void) removeDockApp: (AZDockApp *) app;
- (int) minimalCountToStayInDock;

@end

