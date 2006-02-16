#ifndef __WM_Defaults__
#define __WM_Defaults__

/* To replace default.s amd wPreferences */
#include <AppKit/AppKit.h>
#include "screen.h"

/** window attributes **/
GS_EXPORT NSString * const WAIcon;
GS_EXPORT NSString * const WANoTitlebar;
GS_EXPORT NSString * const WANoResizebar;
GS_EXPORT NSString * const WANoMiniaturizeButton;
GS_EXPORT NSString * const WANoCloseButton;
GS_EXPORT NSString * const WANoBorder;
GS_EXPORT NSString * const WANoHideOthers;
GS_EXPORT NSString * const WANoMouseBindings;
GS_EXPORT NSString * const WANoKeyBindings;
GS_EXPORT NSString * const WANoAppIcon;
GS_EXPORT NSString * const WAKeepOnTop;
GS_EXPORT NSString * const WAKeepOnBottom;
GS_EXPORT NSString * const WAOmnipresent;
GS_EXPORT NSString * const WASkipWindowList;
GS_EXPORT NSString * const WAKeepInsideScreen;
GS_EXPORT NSString * const WAUnfocusable;
GS_EXPORT NSString * const WAAlwaysUserIcon;
GS_EXPORT NSString * const WAStartMiniaturized;
GS_EXPORT NSString * const WAStartHidden;
GS_EXPORT NSString * const WAStartMaximized;
GS_EXPORT NSString * const WADontSaveSession;
GS_EXPORT NSString * const WAEmulateAppIcon;
GS_EXPORT NSString * const WAFullMaximize;
GS_EXPORT NSString * const WASharedAppIcon;
#ifdef XKB_BUTTON_HINT
GS_EXPORT NSString * const WANoLanguageButton;
#endif
GS_EXPORT NSString * const WAStartWorkspace;
GS_EXPORT NSString * const WAAnyWindow;
GS_EXPORT NSString * const WAYes;
GS_EXPORT NSString * const WANo;

@interface WMDefaults: NSObject
{
  NSUserDefaults *defaults;
  NSArray *fallbackWMs;
  NSMutableDictionary *wa; // window attributes;
  NSMutableDictionary *ws; // session attributes;
}

+ (WMDefaults *) sharedDefaults;

/** window attributes **/
- (NSDictionary *) windowAttributes;

- (NSDictionary *) attributesForWindow: (NSString *) name;
- (void) removeWindow: (NSString *) name;
- (void) setAttributes: (NSDictionary *) dict window: (NSString *) name;

- (id) objectForKey: (id) key window: (NSString *) name;
- (void) setObject: (id) object forKey: (NSString *) key 
            window: (NSString *) name;
- (void) removeObjectForKey: (id) key window: (NSString *) name;

/** sessions **/
- (NSDictionary *) sessionStates;
- (NSDictionary *) sessionStatesForScreen: (int) screen;
- (void) setSessionStates: (NSDictionary *) dict forScreen: (int) screen;

/* workspace attributes for screen */
- (NSArray *) workspacesForScreen: (int) screen;
- (void) setWorkspaces: (NSArray *) array forScreen: (int) screen;

/* dock attributes for screen */
- (NSDictionary *) dockForScreen: (int) screen;
- (void) setDock: (NSDictionary *) dict forScreen: (int) screen;

/* clip attributes for screen */
- (NSDictionary *) clipForScreen: (int) screen;
- (void) setClip: (NSDictionary *) dict forScreen: (int) screen;

/* applicatios */
- (NSArray *) applicationsForScreen: (int) screen;
- (void) setApplications: (NSArray *) array forScreen: (int) screen;
- (void) removeApplicationsForScreen: (int) screen;

/* workspace */
- (NSString *) workspaceForScreen: (int) screen;
- (void) setWorkspace: (NSString *) string forScreen: (int) screen;
- (void) removeWorkspaceForScreen: (int) screen;

/* called in -init */
- (void) readStaticDefaults;
- (void) readDefaults: (WScreen *) screen; // called regularly

/* accessories */
- (NSArray *) fallbackWMs;
- (void) setWorkspaceBack: (NSArray *) array screen: (WScreen *) screen;
- (void) synchronize;

@end

#endif /* __WM_Defaults__ */
