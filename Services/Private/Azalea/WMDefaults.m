#include "WMDefaults.h"
#include "WindowMaker.h"
#include "xmodifier.h"
#include "window.h"
#include "keybind.h"
#include "framewin.h"
#include "resources.h"
#include <wraster.h>

extern WPreferences wPreferences;
extern WShortKey wKeyBindings[WKBD_LAST];
extern Cursor wCursor[WCUR_LAST];

static WMDefaults *sharedInstance;

typedef struct BackgroundTexture {
  int refcount;
  int solid;
  char *spec;
  XColor color;
  Pixmap pixmap;                     /* for all textures, including solid */
  int width;                         /* size of the pixmap */
  int height;
} BackgroundTexture;

static int
dummyErrorHandler(Display *dpy, XErrorEvent *err)
{
  return 0;
}

/** static defaults **/
static NSString *WMDColormapSize = @"ColormapSize";
static NSString *WMDDisableDithering = @"DisableDithering";
static NSString *WMDIconSize = @"IconSize";
static NSString *WMDModifierKey = @"ModifierKey";
static NSString *WMDDisableWSMouseActions = @"WMDDisableWSMouseActions";
static NSString *WMDNewStyle = @"NewStyle";
static NSString *WMDDisableDock = @"DisableDock";
static NSString *WMDDisableClip = @"DisableClip";
static NSString *WMDDisableMiniwindows = @"DisableMiniwindows";

/** defaults **/
static NSString *WMDIconPosition = @"IconPosition";
static NSString *WMDIconificationStyle = @"IconificationStyle";
static NSString *WMDMouseLeftButtonAction = @"MouseLeftButtonAction";
static NSString *WMDMouseMiddleButtonAction = @"MouseMiddleButtonAction";
static NSString *WMDMouseRightButtonAction = @"MouseRightButtonAction";
static NSString *WMDMouseWheelAction = @"MouseWheelAction";
static NSString *WMDPixmapPath = @"PixmapPath";
static NSString *WMDIconPath = @"IconPath";
static NSString *WMDColormapMode = @"ColormapMode";
static NSString *WMDAutoFocus = @"AutoFocus";
static NSString *WMDRaiseDelay = @"RaiseDelay";
static NSString *WMDCirculateRaise = @"CirculateRaise";
static NSString *WMDSuperfluous = @"Superfluous";
static NSString *WMDAdvanceToNewWorkspace = @"AdvanceToNewWorkspace";
static NSString *WMDCycleWorkspaces = @"CycleWorkspaces";
static NSString *WMDWorkspaceNameDisplayPosition = @"WorkspaceNameDisplayPosition";
static NSString *WMDWorkspaceBorder = @"WorkspaceBorder";
static NSString *WMDWorkspaceBorderSize = @"WorkspaceBorderSize";

#ifdef VIRTUAL_DESKTOP
static NSString *WMDEnableVirtualDesktop = @"EnableVirtualDesktop";
static NSString *WMDVirtualEdgeExtendSpace = @"VirtualEdgeExtendSpace";
static NSString *WMDVirtualEdgeHorizonScrollSpeed = @"VirtualEdgeHorizonScrollSpeed";
static NSString *WMDVirtualEdgeVerticalScrollSpeed = @"VirtualEdgeVerticalScrollSpeed";
static NSString *WMDVirtualEdgeResistance = @"VirtualEdgeResistance";
static NSString *WMDVirtualEdgeAttraction = @"VirtualEdgeAttraction";
static NSString *WMDVirtualEdgeLeftKey = @"VirtualEdgeLeftKey";
static NSString *WMDVirtualEdgeRightKey = @"VirtualEdgeRightKey";
static NSString *WMDVirtualEdgeUpKey = @"VirtualEdgeUpKey";
static NSString *WMDVirtualEdgeDownKey = @"VirtualEdgeDownKey";
#endif

static NSString *WMDStickyIcons = @"StickyIcons";
static NSString *WMDSaveSessionOnExit = @"SaveSessionOnExit";
static NSString *WMDWrapMenus = @"WrapMenus";
static NSString *WMDScrollableMenus = @"ScrollableMenus";
static NSString *WMDMenuScrollSpeed = @"MenuScrollSpeed";
static NSString *WMDIconSlideSpeed = @"IconSlideSpeed";
static NSString *WMDShadeSpeed = @"ShadeSpeed";
static NSString *WMDDoubleClickTime = @"DoubleClickTime";
static NSString *WMDAlignSubmenus = @"AlignSubmenus";
static NSString *WMDOpenTransientOnOwnerWorkspace = @"OpenTransientOnOwnerWorkspace";
static NSString *WMDWindowPlacement = @"WindowPlacement";
static NSString *WMDIgnoreFocusClick = @"IgnoreFocusClick";
static NSString *WMDUseSaveUnders = @"UseSaveUnders";
static NSString *WMDOpaqueMove = @"OpaqueMove";
static NSString *WMDDisableSound = @"DisableSound";
static NSString *WMDDisableAnimations = @"DisableAnimations";
static NSString *WMDDontLinkWorkspaces = @"DontLinkWorkspaces";
static NSString *WMDAutoArrangeIcons = @"AutoArrangeIcons";
static NSString *WMDNoWindowOverDock = @"NoWindowOverDock";
static NSString *WMDNoWindowOverIcons = @"NoWindowOverIcons";
static NSString *WMDWindowPlaceOrigin = @"WindowPlaceOrigin";
static NSString *WMDResizeDisplay = @"ResizeDisplay";
static NSString *WMDMoveDisplay = @"MoveDisplay";
static NSString *WMDDontConfirmKill = @"DontConfirmKill";
static NSString *WMDWindowTitleBalloons = @"WindowTitleBalloons";
static NSString *WMDMiniwindowTitleBalloons = @"WMDMiniwindowTitleBalloons";
static NSString *WMDAppIconBalloons = @"AppIconBalloons";
static NSString *WMDHelpBalloons = @"HelpBalloons";
static NSString *WMDEdgeResistance = @"EdgeResistance";
static NSString *WMDAttraction = @"Attraction";
static NSString *WMDDisableBlinking = @"DisableBlinking";
static NSString *WMDMenuStyle = @"MenuStyle";
static NSString *WMDWidgetColor = @"WidgetColor";
#if 0
static NSString *WMDWorkspaceSpecificBack = @"WorkspaceSpecificBack";
#endif
static NSString *WMDWorkspaceBack = @"WorkspaceBack";
#if 0
static NSString *WMDSmoothWorkspaceBack = @"SmoothWorkspaceBack";
#endif
static NSString *WMDIconBack = @"IconBack";
static NSString *WMDTitleJustify = @"TitleJustify";
static NSString *WMDWindowTitleFont = @"WindowTitleFont";
static NSString *WMDWindowTitleExtendSpace = @"WindowTitleExtendSpace";
static NSString *WMDMenuTitleExtendSpace = @"MenuTitleExtendSpace";
static NSString *WMDMenuTextExtendSpace = @"MenuTextExtendSpace";
static NSString *WMDMenuTitleFont = @"MenuTitleFont";
static NSString *WMDMenuTextFont = @"MenuTextFont";
static NSString *WMDIconTitleFont = @"IconTitleFont";
static NSString *WMDClipTitleFont = @"ClipTitleFont";
static NSString *WMDLargeDisplayFont = @"LargeDisplayFont";
static NSString *WMDHighlightColor = @"HighlightColor";
static NSString *WMDHighlightTextColor = @"HighlightTextColor";
static NSString *WMDClipTitleColor = @"ClipTitleColor";
static NSString *WMDCClipTitleColor = @"CClipTitleColor"; // collapsed
static NSString *WMDFTitleColor = @"FTitleColor"; // focused
static NSString *WMDPTitleColor = @"PTitleColor";
static NSString *WMDUTitleColor = @"UTitleColor";
static NSString *WMDFTitleBack = @"FTitleBack";
static NSString *WMDPTitleBack = @"PTitleBack";
static NSString *WMDUTitleBack = @"UTitleBack";
static NSString *WMDResizebarBack = @"ResizebarBack";
static NSString *WMDMenuTitleColor = @"MenuTitleColor";
static NSString *WMDMenuTextColor = @"MenuTextColor";
static NSString *WMDMenuDisabledColor = @"MenuDisabledColor";
static NSString *WMDMenuTitleBack = @"MenuTitleBack";
static NSString *WMDMenuTextBack = @"MenuTextBack";
static NSString *WMDIconTitleColor = @"IconTitleColor";
static NSString *WMDIconTitleBack = @"IconTitleBack";
#if 0
static NSString *WMDSwitchPanelImages = @"SwitchPanelImages";
#endif
/* keybindings */
static NSString *WMDRootMenuKey = @"RootMenuKey";
static NSString *WMDWindowListKey = @"WindowListKey";
static NSString *WMDWindowMenuKey = @"WindowMenuKey";
static NSString *WMDClipLowerKey = @"ClipLowerKey";
static NSString *WMDClipRaiseKey = @"ClipRaiseKey";
static NSString *WMDClipRaiseLowerKey = @"ClipRaiseLowerKey";
static NSString *WMDMiniaturizeKey = @"MiniaturizeKey";
static NSString *WMDHideKey = @"HideKey";
static NSString *WMDHideOthersKey = @"HideOthersKey";
static NSString *WMDMoveResizeKey = @"MoveResizeKey";
static NSString *WMDCloseKey = @"CloseKey";
static NSString *WMDMaximizeKey = @"MizimizeKey";
static NSString *WMDVMaximizeKey = @"VMaximizeKey";
static NSString *WMDHMaximizeKey = @"HMaximizeKey";
static NSString *WMDRaiseKey = @"RaiseKey";
static NSString *WMDLowerKey = @"LowerKey";
static NSString *WMDRaiseLowerKey = @"RaiseLowerKey";
static NSString *WMDShadeKey = @"ShadeKey";
static NSString *WMDSelectKey = @"SelectKey";
static NSString *WMDFocusNextKey = @"FocusNextKey";
static NSString *WMDFocusPrevKey = @"FocusPrevKey";
static NSString *WMDNextWorkspaceKey = @"WMDNextWorkspaceKey";
static NSString *WMDPrevWorkspaceKey = @"WMDPrevWorkspaceKey";
static NSString *WMDNextWorkspaceLayerKey = @"WMDNextWorkspaceLayerKey";
static NSString *WMDPrevWorkspaceLayerKey = @"WMDPrevWorkspaceLayerKey";
static NSString *WMDWorkspace1Key = @"Workspace1Key";
static NSString *WMDWorkspace2Key = @"Workspace2Key";
static NSString *WMDWorkspace3Key = @"Workspace3Key";
static NSString *WMDWorkspace4Key = @"Workspace4Key";
static NSString *WMDWorkspace5Key = @"Workspace5Key";
static NSString *WMDWorkspace6Key = @"Workspace6Key";
static NSString *WMDWorkspace7Key = @"Workspace7Key";
static NSString *WMDWorkspace8Key = @"Workspace8Key";
static NSString *WMDWorkspace9Key = @"Workspace9Key";
static NSString *WMDWorkspace10Key = @"Workspace10Key";
static NSString *WMDWindowShortcut1Key = @"WindowShortcut1Key";
static NSString *WMDWindowShortcut2Key = @"WindowShortcut2Key";
static NSString *WMDWindowShortcut3Key = @"WindowShortcut3Key";
static NSString *WMDWindowShortcut4Key = @"WindowShortcut4Key";
static NSString *WMDWindowShortcut5Key = @"WindowShortcut5Key";
static NSString *WMDWindowShortcut6Key = @"WindowShortcut6Key";
static NSString *WMDWindowShortcut7Key = @"WindowShortcut7Key";
static NSString *WMDWindowShortcut8Key = @"WindowShortcut8Key";
static NSString *WMDWindowShortcut9Key = @"WindowShortcut9Key";
static NSString *WMDWindowShortcut10Key = @"WindowShortcut10Key";
static NSString *WMDScreenSwitchKey = @"ScreenSwitchKey";

#ifdef KEEP_XKB_LOCK_STATUS
static NSString *WMDToggleKbdModeKey = @"ToggleKbdModeKey";
static NSString *WMDKbdModeLock = @"KbdModeLock";
#endif

static NSString *WMDNormalCursor = @"NormalCursor";
static NSString *WMDArrowCursor = @"ArrowCursor";
static NSString *WMDMoveCursor = @"MoveCursor";
static NSString *WMDResizeCursor = @"ResizeCursor";
static NSString *WMDTopLeftResizeCursor = @"TopLeftResizeCursor";
static NSString *WMDTopRightResizeCursor = @"TopRightResizeCursor";
static NSString *WMDBottomLeftResizeCursor = @"BottomLeftResizeCursor";
static NSString *WMDBottomRightResizeCursor = @"BottomRightResizeCursor";
static NSString *WMDVerticalResizeCursor = @"VerticalResizeCursor";
static NSString *WMDHorizontalResizeCursor = @"HorizontalResizeCursor";
static NSString *WMDWaitCursor = @"WaitCursor";
static NSString *WMDQuestionCursor = @"QuestionCursor";
static NSString *WMDTextCursor = @"TextCursor";
static NSString *WMDSelectCursor = @"SelectCursor";

/** window attributes **/
NSString * const WDWindowAttributes = @"WindowAttributes";
NSString * const WAIcon = @"Icon";
NSString * const WANoTitlebar = @"NoTitlebar";
NSString * const WANoResizebar = @"NoResizebar";
NSString * const WANoMiniaturizeButton = @"NoMiniaturizeButton";
NSString * const WANoCloseButton = @"NoCloseButton";
NSString * const WANoBorder = @"NoBorder";
NSString * const WANoHideOthers = @"NoHideOthers";
NSString * const WANoMouseBindings = @"NoMouseBindings";
NSString * const WANoKeyBindings = @"NoKeyBindings";
NSString * const WANoAppIcon = @"NoAppIcon";
NSString * const WAKeepOnTop = @"KeepOnTop";
NSString * const WAKeepOnBottom = @"KeepOnBottom";
NSString * const WAOmnipresent = @"Omnipresent";
NSString * const WASkipWindowList = @"SkipWindowList";
NSString * const WAKeepInsideScreen = @"KeepInsideScreen";
NSString * const WAUnfocusable = @"Unfocusable";
NSString * const WAAlwaysUserIcon = @"AlwaysUserIcon";
NSString * const WAStartMiniaturized = @"StartMiniaturized";
NSString * const WAStartHidden = @"StartHidden";
NSString * const WAStartMaximized = @"StartMaximized";
NSString * const WADontSaveSession = @"DontSaveSession";
NSString * const WAEmulateAppIcon = @"EmulateAppIcon";
NSString * const WAFullMaximize = @"FullMaximize";
NSString * const WASharedAppIcon = @"SharedAppIcon";
#ifdef XKB_BUTTON_HINT
NSString * const WANoLanguageButton = @"NoLanguageButton";
#endif
NSString * const WAStartWorkspace = @"StartWorkspace";
NSString * const WAAnyWindow = @"*";
NSString * const WAYes = @"YES";
NSString * const WANo = @"NO";

/** session attributes **/
static NSString *WDSessionStates = @"SessionStates";
static NSString *WSWorkspaces = @"Workspaces";
static NSString *WSDock = @"Dock";
static NSString *WSClip= @"Clip";
static NSString *WSApplications = @"Applications";
static NSString *WSWorkspace = @"Workspace";

@interface WMDefaults (WMPrivate)
- (void) bind: (int) keybind withKey: (NSString *) key 
                              screen: (WScreen *) screen;
- (Cursor) cursorFromArray: (NSArray *) array;
- (void) bind: (int) cur withCursor: (NSArray *) cursor 
                                screen: (WScreen *) screen;
- (char *) pathList: (NSArray *) array;
- (WCoord) coordFromPoint: (NSValue *) point screen: (WScreen *) screen;
- (void) updateUsableArea: (WScreen *) screen;
- (XColor *) colorFromString: (NSString *) string screen: (WScreen *) screen;
- (void) setHighlight: (XColor *) color screen: (WScreen *) scr;
- (void) setHighlightText: (XColor *) color screen: (WScreen *) scr;
- (void) setClipTitle: (int) index color: (XColor *) color 
               screen: (WScreen *) screen;
- (void) setWindowTitle: (int) index color: (XColor *) color 
               screen: (WScreen *) screen;
- (void) setMenuTitle: (XColor *) color 
               screen: (WScreen *) screen;
- (void) setMenuText: (XColor *) color 
               screen: (WScreen *) screen;
- (void) setMenuDisabled: (XColor *) color 
               screen: (WScreen *) screen;
- (void) setIconTitleColor: (XColor *) color 
               screen: (WScreen *) screen;
- (void) setIconTitleBack: (XColor *) color 
               screen: (WScreen *) screen;
- (WMFont *) fontFromString: (NSString *) stringValue screen: (WScreen *) scr;
- (void) setWinTitleFont: (WMFont *) font screen: (WScreen *) scr;
- (void) setMenuTitleFont: (WMFont *) font screen: (WScreen *) scr;
- (void) setMenuTextFont: (WMFont *) font screen: (WScreen *) scr;
- (void) setIconTitleFont: (WMFont *) font screen: (WScreen *) scr;
- (void) setClipTitleFont: (WMFont *) font screen: (WScreen *) scr;
- (void) setLargeDisplayFont: (WMFont *) font screen: (WScreen *) scr;
- (WTexture *) widgetTextureFromArray: (NSArray *) a screen: (WScreen *) scr;
- (WTexture *) textureFromArray: (NSArray *) a screen: (WScreen *) scr;
- (void) setWidgetColor: (WTexture *) texture screen: (WScreen *) scr;
- (WTexture *) parseTexture: (NSArray *) array screen: (WScreen *) scr;
- (void) setIconTile: (WTexture *) texture screen: (WScreen *) scr;
- (void) setFTitleBack: (WTexture *) texture screen: (WScreen *) scr;
- (void) setPTitleBack: (WTexture *) texture screen: (WScreen *) scr;
- (void) setUTitleBack: (WTexture *) texture screen: (WScreen *) scr;
- (void) setResizebarBack: (WTexture *) texture screen: (WScreen *) scr;
- (void) setMenuTitleBack: (WTexture *) texture screen: (WScreen *) scr;
- (void) setMenuTextBack: (WTexture *) texture screen: (WScreen *) scr;
- (void) setWorkspaceBack: (NSArray *) array screen: (WScreen *) scr;

@end

@implementation WMDefaults

+ (WMDefaults *) sharedDefaults
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[WMDefaults alloc] init];
  }
  return sharedInstance;
}

- (id) init
{
  self = [super init];

  ASSIGN(defaults, [NSUserDefaults standardUserDefaults]);

  /** WindowMaker Defaults **/
  [defaults registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
	@"SelectWindows", 		WMDMouseLeftButtonAction,
	@"OpenWindowListMenu", 		WMDMouseMiddleButtonAction,
	@"OpenApplicationsMenu", 	WMDMouseRightButtonAction,
#ifdef VIRTUAL_DESKTOP
	@"30", 				WMDVirtualEdgeHorizonScrollSpeed,
	@"30", 				WMDVirtualEdgeVerticalScrollSpeed,
	@"30", 				WMDVirtualEdgeResistance,
	@"30", 				WMDVirtualEdgeAttraction,
#endif
	@"250", 			WMDDoubleClickTime,
	@"30", 				WMDEdgeResistance,
	@"YES", 			WMDAutoFocus,
	@"YES", 			WMDNewStyle,
	@"Control+Escape",		WMDWindowMenuKey,
	@"Mod1+Tab",			WMDFocusNextKey,
	@"Mod1+Shift+Tab", 		WMDFocusPrevKey,
	@"white", 			WMDHighlightColor,
	@"black", 			WMDHighlightTextColor,
	@"black", 			WMDClipTitleColor,
	@"#454045", 			WMDCClipTitleColor,
	@"white", 			WMDFTitleColor,
	@"white",			WMDPTitleColor,
	@"black",			WMDUTitleColor,
	@"white",			WMDMenuTitleColor,
	@"black",			WMDMenuTextColor,
	@"#616161",			WMDMenuDisabledColor,
	@"white",			WMDIconTitleColor,
	@"black",			WMDIconTitleBack,
	[NSString stringWithCString: DEF_TITLE_FONT],
					WMDWindowTitleFont,
	[NSString stringWithCString: DEF_MENU_TITLE_FONT],
					WMDMenuTitleFont,
	[NSString stringWithCString: DEF_MENU_ENTRY_FONT],
					WMDMenuTextFont,
	[NSString stringWithCString: DEF_ICON_TITLE_FONT],
					WMDIconTitleFont,
	[NSString stringWithCString: DEF_CLIP_TITLE_FONT],
					WMDClipTitleFont,
	[NSString stringWithCString: DEF_WORKSPACE_NAME_FONT],
					WMDLargeDisplayFont,
	[NSValue valueWithPoint: NSMakePoint(64, 64)],
					WMDWindowPlaceOrigin,
  [NSArray arrayWithObjects: @"~/pixmaps", @"~/GNUstep/Library/Icons",
	@"/usr/local/share/WindowMaker/Icons",
	@"/usr/share/WindowMaker/Icons",
	@"/usr/local/share/icons", @"/usr/share/icons",
	@"/usr/X11R6/include/X11/pixmaps", nil], 
	  				WMDIconPath,
  [NSArray arrayWithObjects: @"~/pixmaps", 
	@"~/GNUstep/Library/WindowMaker/Backgrounds",
	@"~/GNUstep/Library/WindowMaker/Pixmaps",
	@"/usr/local/share/WindowMaker/Backgrounds",
	@"/usr/local/share/WindowMaker/Pixmaps",
	@"/usr/share/WindowMaker/Backgrounds",
	@"/usr/share/WindowMaker/Pixmaps",
	@"/usr/local/share/pixmaps", @"/usr/share/pixmaps",
	@"/usr/X11R6/include/X11/pixmaps", nil], 
	  				WMDPixmapPath,
  [NSArray arrayWithObjects: @"builtin", @"left_ptr", nil], 
	  				WMDNormalCursor,
  [NSArray arrayWithObjects: @"builtin", @"top_left_arrow", nil], 
	  				WMDArrowCursor,
  [NSArray arrayWithObjects: @"builtin", @"fleur", nil], 
	  				WMDMoveCursor,
  [NSArray arrayWithObjects: @"builtin", @"sizing", nil], 
	  				WMDResizeCursor,
  [NSArray arrayWithObjects: @"builtin", @"top_left_corner", nil], 
	  				WMDTopLeftResizeCursor,
  [NSArray arrayWithObjects: @"builtin", @"top_right_corner", nil], 
	  				WMDTopRightResizeCursor,
  [NSArray arrayWithObjects: @"builtin", @"bottom_left_corner", nil], 
	  				WMDBottomLeftResizeCursor,
  [NSArray arrayWithObjects: @"builtin", @"bottom_right_corner", nil], 
	  				WMDBottomRightResizeCursor,
  [NSArray arrayWithObjects: @"builtin", @"sb_v_double_arrow", nil], 
	  				WMDVerticalResizeCursor,
  [NSArray arrayWithObjects: @"builtin", @"sb_h_double_arrow", nil], 
	  				WMDHorizontalResizeCursor,
  [NSArray arrayWithObjects: @"builtin", @"watch", nil], 
	  				WMDWaitCursor,
  [NSArray arrayWithObjects: @"builtin", @"question_arrow", nil], 
	  				WMDQuestionCursor,
  [NSArray arrayWithObjects: @"builtin", @"xterm", nil], 
	  				WMDTextCursor,
  [NSArray arrayWithObjects: @"builtin", @"cross", nil], 
	  				WMDSelectCursor,
  [NSArray arrayWithObjects: @"solid", @"gray", nil], 
	  				WMDWidgetColor,
  [NSArray arrayWithObjects: @"solid", @"gray", nil], 
	  				WMDIconBack,
  [NSArray arrayWithObjects: @"solid", @"black", nil], 
	  				WMDFTitleBack,
  [NSArray arrayWithObjects: @"solid", @"#616161", nil], 
	  				WMDPTitleBack,
  [NSArray arrayWithObjects: @"solid", @"gray", nil], 
	  				WMDUTitleBack,
  [NSArray arrayWithObjects: @"solid", @"gray", nil], 
	  				WMDResizebarBack,
  [NSArray arrayWithObjects: @"solid", @"black", nil], 
	  				WMDMenuTitleBack,
  [NSArray arrayWithObjects: @"solid", @"gray", nil], 
	  				WMDMenuTextBack,
  [NSArray arrayWithObjects: @"solid", @"#414141", nil], 
	  				WMDWorkspaceBack,
	  nil]];

  NSMutableArray *fallback = [[NSMutableArray alloc] init];
  char *alt = getenv("WINDOWMAKER_ALT_WM");
  if (alt != NULL)
  {
    [fallback addObject: [NSString stringWithCString: alt]];
  }
  [fallback addObject: [NSString stringWithCString: "blackbox"]];
  [fallback addObject: [NSString stringWithCString: "metacity"]];
  [fallback addObject: [NSString stringWithCString: "fvwm"]];
  [fallback addObject: [NSString stringWithCString: "twm"]];
  [fallback addObject: [NSString stringWithCString: "rxvt"]];
  [fallback addObject: [NSString stringWithCString: "xterm"]];
  ASSIGNCOPY(fallbackWMs, fallback);
  DESTROY(fallback);

  [self readStaticDefaults];

  /* from WINGsConfiguration */
  if (wPreferences.mouseWheelUp == 0)
    wPreferences.mouseWheelUp = Button4;
  if (wPreferences.mouseWheelDown == 0)
    wPreferences.mouseWheelDown = Button5;

  /* window attributes */
  if ([defaults objectForKey: WDWindowAttributes] == nil)
  {
    /* create empty one */
    ASSIGN(wa, AUTORELEASE([[NSMutableDictionary alloc] init]));
    [wa setObject: 
	  [NSDictionary dictionaryWithObject: @"clip.tiff" forKey: WAIcon]
  					forKey: @"Logo.WMClip"];
    [wa setObject:
	  [NSDictionary dictionaryWithObject: @"clip.tiff" forKey: WAIcon]
  					forKey: @"Tile.WMClip"];
    [wa setObject: 
	  [NSDictionary dictionaryWithObject: @"GNUstep.tiff" forKey: WAIcon]
  					forKey: @"Logo.WMPanel"];
    [wa setObject:
	  [NSDictionary dictionaryWithObject: @"GNUstep.tiff" forKey: WAIcon]
  					forKey: @"Logo.WMDock"];
    [wa setObject:
	  [NSDictionary dictionaryWithObject: @"GNUstep.tiff" forKey: WAIcon]
  					forKey: @"Dockit"];
    [wa setObject:
	  [NSDictionary dictionaryWithObject: @"GNUterm.tiff" forKey: WAIcon]
  					forKey: @"XTerm"];
    [wa setObject:
	  [NSDictionary dictionaryWithObject: @"GNUterm.tiff" forKey: WAIcon]
  					forKey: @"Rxvt"];
    [wa setObject:
	  [NSDictionary dictionaryWithObject: WAYes forKey: WANoAppIcon]
  					forKey: @"panel"];
    [wa setObject:
	  [NSDictionary dictionaryWithObject: @"defaultAppIcon.tiff" forKey: WAIcon]
  					forKey: WAAnyWindow];
  }
  else
  {
    ASSIGN(wa, [NSMutableDictionary dictionaryWithDictionary: [defaults objectForKey: WDWindowAttributes]]);
  }

  /** session **/
  if ([defaults objectForKey: WDSessionStates] == nil)
  {
    /* create empty one */
    ASSIGN(ws, AUTORELEASE([[NSMutableDictionary alloc] init]));
  }
  else
  {
    ASSIGN(ws, [NSMutableDictionary dictionaryWithDictionary: [defaults objectForKey: WDSessionStates]]);
  }

  return self;
}

- (void) dealloc
{
  DESTROY(fallbackWMs);
  DESTROY(defaults);
  DESTROY(wa);
  DESTROY(ws);
  [super dealloc];
}

/** for key binding **/
#define BIND(x, y) \
  { \
    stringValue = [defaults stringForKey: x]; \
    [self bind: y withKey: stringValue screen: scr]; \
  }

- (void) readDefaults: (WScreen *) scr;
{
  int i;
  id object;
  NSString *stringValue;
  BOOL needs_refresh = NO;
  XColor *color;
  WMFont *font;
  WTexture *texture;

  stringValue = [defaults stringForKey: WMDIconPosition];
  if ([stringValue isEqualToString: @"blv"])
    wPreferences.icon_yard = IY_BOTTOM|IY_LEFT|IY_VERT;
  else if ([stringValue isEqualToString: @"brv"])
    wPreferences.icon_yard = IY_BOTTOM|IY_RIGHT|IY_VERT;
  else if ([stringValue isEqualToString: @"brh"])
    wPreferences.icon_yard = IY_BOTTOM|IY_RIGHT|IY_HORIZ;
  else if ([stringValue isEqualToString: @"tlv"])
    wPreferences.icon_yard = IY_TOP|IY_LEFT|IY_VERT;
  else if ([stringValue isEqualToString: @"tlh"])
    wPreferences.icon_yard = IY_TOP|IY_LEFT|IY_HORIZ;
  else if ([stringValue isEqualToString: @"trv"])
    wPreferences.icon_yard = IY_TOP|IY_RIGHT|IY_VERT;
  else if ([stringValue isEqualToString: @"trh"]) 
    wPreferences.icon_yard = IY_TOP|IY_RIGHT|IY_HORIZ;
  else /* if ([stringValue isEqualToString: @"blh"]) */
    wPreferences.icon_yard = IY_BOTTOM|IY_LEFT|IY_HORIZ;
  wScreenUpdateUsableArea(scr);
  wArrangeIcons(scr, True);

  stringValue = [defaults stringForKey: WMDIconificationStyle];
  if ([stringValue isEqualToString: @"Twist"])
    wPreferences.iconification_style = WIS_TWIST;
  else if ([stringValue isEqualToString: @"Flip"])
    wPreferences.iconification_style = WIS_FLIP;
  else if ([stringValue isEqualToString: @"None"])
    wPreferences.iconification_style = WIS_NONE;
  else if ([stringValue isEqualToString: @"random"]) 
    wPreferences.iconification_style = WIS_RANDOM;
  else /* ([stringValue isEqualToString: @"Zoom"]) */
    wPreferences.iconification_style = WIS_ZOOM;

  for (i = 0; i < 3; i++)
  {
    int state;

    switch(i) {
      case 0:
        stringValue = [defaults stringForKey: WMDMouseLeftButtonAction];
	break;
      case 1:
        stringValue = [defaults stringForKey: WMDMouseMiddleButtonAction];
	break;
      case 2:
        stringValue = [defaults stringForKey: WMDMouseRightButtonAction];
	break;
    }

    if ([stringValue isEqualToString: @"None"])
      state = WA_NONE;
    else if ([stringValue isEqualToString: @"SelectWindows"])
      state = WA_SELECT_WINDOWS;
    else if ([stringValue isEqualToString: @"OpenApplicationsMenu"])
      state = WA_OPEN_APPMENU;
    else /* ([stringValue isEqualToString: @"OpenWindowListMenu"]) */
      state = WA_OPEN_WINLISTMENU;

    switch(i) {
      case 0:
	wPreferences.mouse_button1 = state;
	break;
      case 1:
	wPreferences.mouse_button2 = state;
	break;
      case 2:
	wPreferences.mouse_button3 = state;
	break;
    }
  }

  stringValue = [defaults stringForKey: WMDMouseWheelAction];
  if ([stringValue isEqualToString: @"SwitchWorkspaces"])
    wPreferences.mouse_wheel = WA_SWITCH_WORKSPACES;
  else /* if ([stringValue isEqualToString: @"None"]) */
    wPreferences.mouse_wheel = WA_NONE;

  stringValue = [defaults stringForKey: WMDColormapMode];
  if ([stringValue isEqualToString: @"Manual"])
    wPreferences.colormap_mode = WCM_CLICK;
  else /* if ([stringValue isEqualToString: @"Auto"]) */
    wPreferences.colormap_mode = WCM_POINTER;

  stringValue = [defaults stringForKey: WMDWorkspaceNameDisplayPosition];
  if ([stringValue isEqualToString: @"none"])
    wPreferences.workspace_name_display_position = WD_NONE;
  else if ([stringValue isEqualToString: @"top"])
    wPreferences.workspace_name_display_position = WD_TOP;
  else if ([stringValue isEqualToString: @"bottom"])
    wPreferences.workspace_name_display_position = WD_BOTTOM;
  else if ([stringValue isEqualToString: @"topleft"])
    wPreferences.workspace_name_display_position = WD_TOPLEFT;
  else if ([stringValue isEqualToString: @"topright"])
    wPreferences.workspace_name_display_position = WD_TOPRIGHT;
  else if ([stringValue isEqualToString: @"bottomleft"])
    wPreferences.workspace_name_display_position = WD_BOTTOMLEFT;
  else if ([stringValue isEqualToString: @"bottomright"])
    wPreferences.workspace_name_display_position = WD_BOTTOMRIGHT;
  else /* if ([stringValue isEqualToString: @"center"]) */
    wPreferences.workspace_name_display_position = WD_CENTER;

  for (i = 0; i < 3; i++)
  {
    int state;

    switch(i) {
      case 0:
        stringValue = [defaults stringForKey: WMDMenuScrollSpeed];
	break;
      case 1:
        stringValue = [defaults stringForKey: WMDIconSlideSpeed];
	break;
      case 2:
        stringValue = [defaults stringForKey: WMDShadeSpeed];
	break;
    }

    if ([stringValue isEqualToString: @"UltraFast"])
      state = SPEED_ULTRAFAST;
    else if ([stringValue isEqualToString: @"Fast"])
      state = SPEED_FAST;
    else if ([stringValue isEqualToString: @"Slow"])
      state = SPEED_SLOW;
    else if ([stringValue isEqualToString: @"UltraSlow"])
      state = SPEED_ULTRASLOW;
    else /* ([stringValue isEqualToString: @"Medium"]) */
      state = SPEED_MEDIUM;

    switch(i) {
      case 0:
	wPreferences.menu_scroll_speed = state;
	break;
      case 1:
	wPreferences.icon_slide_speed = state;
	break;
      case 2:
	wPreferences.shade_speed = state;
	break;
    }
  }

  stringValue = [defaults stringForKey: WMDWindowPlacement];
  if ([stringValue isEqualToString: @"Smart"])
    wPreferences.window_placement = WPM_SMART;
  else if ([stringValue isEqualToString: @"Cascade"])
    wPreferences.window_placement = WPM_CASCADE;
  else if ([stringValue isEqualToString: @"Random"])
    wPreferences.window_placement = WPM_RANDOM;
  else if ([stringValue isEqualToString: @"Manual"])
    wPreferences.window_placement = WPM_MANUAL;
  else /* if ([stringValue isEqualToString: @"Auto"]) */
    wPreferences.window_placement = WPM_AUTO;

  for (i = 0; i < 2; i++)
  {
    int state;

    switch(i) {
      case 0:
        stringValue = [defaults stringForKey: WMDResizeDisplay];
	break;
      case 1:
        stringValue = [defaults stringForKey: WMDMoveDisplay];
	break;
    }

    if ([stringValue isEqualToString: @"None"])
      state = WDIS_NONE;
    else if ([stringValue isEqualToString: @"Center"])
      state = WDIS_CENTER;
    else if ([stringValue isEqualToString: @"Floating"])
      state = WDIS_FRAME_CENTER;
    else if ([stringValue isEqualToString: @"Line"])
      state = WDIS_NEW;
    else /* ([stringValue isEqualToString: @"Corner"]) */
      state = WDIS_TOPLEFT;

    switch(i) {
      case 0:
	wPreferences.size_display = state;
	break;
      case 1:
	wPreferences.move_display = state;
	break;
    }
  }

  /* free previous one */
  if (wPreferences.pixmap_path != NULL)
    wfree(wPreferences.pixmap_path);
  object = [defaults objectForKey: WMDPixmapPath];
  wPreferences.pixmap_path = [self pathList: object];
  if (wPreferences.icon_path != NULL)
    wfree(wPreferences.icon_path);
  object = [defaults objectForKey: WMDIconPath];
  wPreferences.icon_path = [self pathList: object];

  object = [defaults objectForKey: WMDWindowPlaceOrigin];
  wPreferences.window_place_origin = [self coordFromPoint: object screen: scr];

  {
  stringValue = [defaults objectForKey: WMDWorkspaceBorder];
  if ([stringValue isEqualToString: @"LeftRight"])
    wPreferences.workspace_border_position = WB_LEFTRIGHT;
  else if ([stringValue isEqualToString: @"TopBottom"])
    wPreferences.workspace_border_position = WB_TOPBOTTOM;
  else if ([stringValue isEqualToString: @"AllDirections"])
    wPreferences.workspace_border_position = WB_ALLDIRS;
  else /* if ([stringValue isEqualToString: @"None"]) */
    wPreferences.workspace_border_position = WB_NONE;

  wPreferences.workspace_border_size = [defaults integerForKey: WMDWorkspaceBorderSize];

  wPreferences.no_window_over_dock = [defaults boolForKey: WMDNoWindowOverDock];
  wPreferences.no_window_over_icons = [defaults boolForKey: WMDNoWindowOverIcons];
  [self updateUsableArea: scr];
  }

  stringValue = [defaults stringForKey: WMDMenuStyle];
  if ([stringValue isEqualToString: @"SingleTexture"])
    wPreferences.menu_style = MS_SINGLE_TEXTURE;
  else if ([stringValue isEqualToString: @"Flat"])
    wPreferences.menu_style = MS_FLAT;
  else /* if ([stringValue isEqualToString: @"Normal"]) */
    wPreferences.menu_style = MS_NORMAL;

  stringValue = [defaults stringForKey: WMDTitleJustify];
  if ([stringValue isEqualToString: @"Left"])
    wPreferences.title_justification = WTJ_LEFT;
  else if ([stringValue isEqualToString: @"Right"])
    wPreferences.title_justification = WTJ_RIGHT;
  else /* if ([stringValue isEqualToString: @"Center"]) */
    wPreferences.title_justification = WTJ_CENTER;

  stringValue = [defaults stringForKey: WMDHighlightColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setHighlight: color screen: scr];

  stringValue = [defaults stringForKey: WMDHighlightTextColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setHighlightText: color screen: scr];

  stringValue = [defaults stringForKey: WMDClipTitleColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setClipTitle: CLIP_NORMAL color: color screen: scr];

  stringValue = [defaults stringForKey: WMDCClipTitleColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setClipTitle: CLIP_COLLAPSED color: color screen: scr];

  stringValue = [defaults stringForKey: WMDFTitleColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setWindowTitle: WS_FOCUSED color: color screen: scr];

  stringValue = [defaults stringForKey: WMDPTitleColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setWindowTitle: WS_PFOCUSED color: color screen: scr];

  stringValue = [defaults stringForKey: WMDUTitleColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setWindowTitle: WS_UNFOCUSED color: color screen: scr];

  stringValue = [defaults stringForKey: WMDMenuTitleColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setMenuTitle: color screen: scr];

  stringValue = [defaults stringForKey: WMDMenuTextColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setMenuText: color screen: scr];

  stringValue = [defaults stringForKey: WMDMenuDisabledColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setMenuDisabled: color screen: scr];

  stringValue = [defaults stringForKey: WMDIconTitleColor];
  color = [self colorFromString: stringValue screen: scr];
  [self setIconTitleColor: color screen: scr];

  stringValue = [defaults stringForKey: WMDIconTitleBack];
  color = [self colorFromString: stringValue screen: scr];
  [self setIconTitleBack: color screen: scr];

  stringValue = [defaults stringForKey: WMDWindowTitleFont];
  font = [self fontFromString: stringValue screen: scr];
  [self setWinTitleFont: font screen: scr];

  stringValue = [defaults stringForKey: WMDMenuTitleFont];
  font = [self fontFromString: stringValue screen: scr];
  [self setMenuTitleFont: font screen: scr];

  stringValue = [defaults stringForKey: WMDMenuTextFont];
  font = [self fontFromString: stringValue screen: scr];
  [self setMenuTextFont: font screen: scr];

  stringValue = [defaults stringForKey: WMDIconTitleFont];
  font = [self fontFromString: stringValue screen: scr];
  [self setIconTitleFont: font screen: scr];

  stringValue = [defaults stringForKey: WMDClipTitleFont];
  font = [self fontFromString: stringValue screen: scr];
  [self setClipTitleFont: font screen: scr];

  stringValue = [defaults stringForKey: WMDLargeDisplayFont];
  font = [self fontFromString: stringValue screen: scr];
  [self setLargeDisplayFont: font screen: scr];

  wPreferences.window_title_clearance = [defaults integerForKey: WMDWindowTitleExtendSpace];
  wPreferences.menu_title_clearance = [defaults integerForKey: WMDMenuTitleExtendSpace];
  wPreferences.menu_text_clearance = [defaults integerForKey: WMDMenuTextExtendSpace];

  wPreferences.auto_focus = [defaults boolForKey: WMDAutoFocus];
  wPreferences.raise_delay = [defaults boolForKey: WMDRaiseDelay];
  wPreferences.circ_raise = [defaults boolForKey: WMDCirculateRaise];
  wPreferences.superfluous = [defaults boolForKey: WMDSuperfluous];
  wPreferences.ws_advance = [defaults boolForKey: WMDAdvanceToNewWorkspace];
  wPreferences.ws_cycle = [defaults boolForKey: WMDCycleWorkspaces];

#ifdef VIRTUAL_DESKTOP
  wPreferences.vdesk_enable = [defaults boolForKey: WMDEnableVirtualDesktop];
  wPreferences.vedge_bordersize = [defaults integerForKey: WMDVirtualEdgeExtendSpace];
  wPreferences.vedge_hscrollspeed = [defaults integerForKey: WMDVirtualEdgeHorizonScrollSpeed];
  wPreferences.vedge_vscrollspeed = [defaults integerForKey: WMDVirtualEdgeVerticalScrollSpeed];
  wPreferences.vedge_resistance = [defaults integerForKey: WMDVirtualEdgeResistance];
  wPreferences.vedge_attraction = [defaults integerForKey: WMDVirtualEdgeAttraction];

  BIND(WMDVirtualEdgeLeftKey, WKBD_VDESK_LEFT);
  BIND(WMDVirtualEdgeRightKey, WKBD_VDESK_RIGHT);
  BIND(WMDVirtualEdgeUpKey, WKBD_VDESK_UP);
  BIND(WMDVirtualEdgeDownKey, WKBD_VDESK_DOWN);

  wWorkspaceUpdateEdge(scr);
#endif

  {
    wPreferences.sticky_icons = [defaults boolForKey: WMDStickyIcons];
    if (scr->workspaces) {
      wWorkspaceForceChange(scr, scr->current_workspace);
      wArrangeIcons(scr, False);
    }
  }

  wPreferences.dblclick_time = [defaults integerForKey: WMDDoubleClickTime];
  if (wPreferences.dblclick_time < 0)
    wPreferences.dblclick_time = 1;

  wPreferences.save_session_on_exit = [defaults boolForKey: WMDSaveSessionOnExit];
  wPreferences.wrap_menus = [defaults boolForKey: WMDWrapMenus];
  wPreferences.scrollable_menus = [defaults boolForKey: WMDScrollableMenus];

  wPreferences.align_menus = [defaults boolForKey: WMDAlignSubmenus];
  wPreferences.open_transients_with_parent = [defaults boolForKey: WMDOpenTransientOnOwnerWorkspace];

  wPreferences.ignore_focus_click = [defaults boolForKey: WMDIgnoreFocusClick];
  wPreferences.use_saveunders = [defaults boolForKey: WMDUseSaveUnders];
  wPreferences.opaque_move = [defaults boolForKey: WMDOpaqueMove];
  wPreferences.no_sound = [defaults boolForKey: WMDDisableSound];
  wPreferences.no_animations = [defaults boolForKey: WMDDisableAnimations];
  wPreferences.no_autowrap = [defaults boolForKey: WMDDontLinkWorkspaces];
  wPreferences.auto_arrange_icons = [defaults boolForKey: WMDAutoArrangeIcons];

  wPreferences.dont_confirm_kill = [defaults boolForKey: WMDDontConfirmKill];
  wPreferences.window_balloon = [defaults boolForKey: WMDWindowTitleBalloons];
  wPreferences.miniwin_balloon = [defaults boolForKey: WMDMiniwindowTitleBalloons];
  wPreferences.appicon_balloon = [defaults boolForKey: WMDAppIconBalloons];
  wPreferences.help_balloon = [defaults boolForKey: WMDHelpBalloons];

  wPreferences.edge_resistance = [defaults integerForKey: WMDEdgeResistance];

  wPreferences.attract = [defaults boolForKey: WMDAttraction];
  wPreferences.dont_blink = [defaults boolForKey: WMDDisableBlinking];

  /* key binding */
  BIND(WMDRootMenuKey, WKBD_ROOTMENU);
  BIND(WMDWindowListKey, WKBD_WINDOWLIST);
  BIND(WMDWindowMenuKey, WKBD_WINDOWMENU);
  BIND(WMDClipLowerKey, WKBD_CLIPLOWER);
  BIND(WMDClipRaiseKey, WKBD_CLIPRAISE);
  BIND(WMDClipRaiseLowerKey, WKBD_CLIPRAISELOWER);
  BIND(WMDMiniaturizeKey, WKBD_MINIATURIZE);
  BIND(WMDHideKey, WKBD_HIDE);
  BIND(WMDHideOthersKey, WKBD_HIDE_OTHERS);
  BIND(WMDMoveResizeKey, WKBD_MOVERESIZE);
  BIND(WMDCloseKey, WKBD_CLOSE);
  BIND(WMDMaximizeKey, WKBD_MAXIMIZE);
  BIND(WMDVMaximizeKey, WKBD_VMAXIMIZE);
  BIND(WMDHMaximizeKey, WKBD_HMAXIMIZE);
  BIND(WMDRaiseKey, WKBD_RAISE);
  BIND(WMDLowerKey, WKBD_LOWER);
  BIND(WMDRaiseLowerKey, WKBD_RAISELOWER);
  BIND(WMDShadeKey, WKBD_SHADE);
  BIND(WMDSelectKey, WKBD_SELECT);
  BIND(WMDFocusNextKey, WKBD_FOCUSNEXT);
  BIND(WMDFocusPrevKey, WKBD_FOCUSPREV);
  BIND(WMDNextWorkspaceKey, WKBD_NEXTWORKSPACE);
  BIND(WMDPrevWorkspaceKey, WKBD_PREVWORKSPACE);
  BIND(WMDNextWorkspaceLayerKey, WKBD_NEXTWSLAYER);
  BIND(WMDPrevWorkspaceLayerKey, WKBD_PREVWSLAYER);
  BIND(WMDWorkspace1Key, WKBD_WORKSPACE1);
  BIND(WMDWorkspace2Key, WKBD_WORKSPACE2);
  BIND(WMDWorkspace3Key, WKBD_WORKSPACE3);
  BIND(WMDWorkspace4Key, WKBD_WORKSPACE4);
  BIND(WMDWorkspace5Key, WKBD_WORKSPACE5);
  BIND(WMDWorkspace6Key, WKBD_WORKSPACE6);
  BIND(WMDWorkspace7Key, WKBD_WORKSPACE7);
  BIND(WMDWorkspace8Key, WKBD_WORKSPACE8);
  BIND(WMDWorkspace9Key, WKBD_WORKSPACE9);
  BIND(WMDWorkspace10Key, WKBD_WORKSPACE10);
  BIND(WMDWindowShortcut1Key, WKBD_WINDOW1);
  BIND(WMDWindowShortcut2Key, WKBD_WINDOW2);
  BIND(WMDWindowShortcut3Key, WKBD_WINDOW3);
  BIND(WMDWindowShortcut4Key, WKBD_WINDOW4);
  BIND(WMDWindowShortcut5Key, WKBD_WINDOW5);
  BIND(WMDWindowShortcut6Key, WKBD_WINDOW6);
  BIND(WMDWindowShortcut7Key, WKBD_WINDOW7);
  BIND(WMDWindowShortcut8Key, WKBD_WINDOW8);
  BIND(WMDWindowShortcut9Key, WKBD_WINDOW9);
  BIND(WMDWindowShortcut10Key, WKBD_WINDOW10);
  BIND(WMDScreenSwitchKey, WKBD_SWITCH_SCREEN);

#ifdef KEEP_XKB_LOCK_STATUS
  BIND(WMDToggleKbdModeKey, WKBD_TOGGLE);
  wPreferences.modelock = [defaults boolForKey: WMDKbdModeLock];
#endif

  /* Cursor */
  object = [defaults objectForKey: WMDNormalCursor]; 
  [self bind: WCUR_ROOT withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDArrowCursor]; 
  [self bind: WCUR_ARROW withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDMoveCursor]; 
  [self bind: WCUR_MOVE withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDResizeCursor]; 
  [self bind: WCUR_RESIZE withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDTopLeftResizeCursor]; 
  [self bind: WCUR_TOPLEFTRESIZE withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDTopRightResizeCursor]; 
  [self bind: WCUR_TOPRIGHTRESIZE withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDBottomLeftResizeCursor]; 
  [self bind: WCUR_BOTTOMLEFTRESIZE withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDBottomRightResizeCursor]; 
  [self bind: WCUR_BOTTOMRIGHTRESIZE withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDVerticalResizeCursor]; 
  [self bind: WCUR_VERTICALRESIZE withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDHorizontalResizeCursor]; 
  [self bind: WCUR_HORIZONRESIZE withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDWaitCursor]; 
  [self bind: WCUR_WAIT withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDQuestionCursor]; 
  [self bind: WCUR_QUESTION withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDTextCursor]; 
  [self bind: WCUR_TEXT withCursor: object screen: scr]; 
  object = [defaults objectForKey: WMDSelectCursor]; 
  [self bind: WCUR_SELECT withCursor: object screen: scr]; 

  /* texture */
  object = [defaults objectForKey: WMDWidgetColor];
  texture = [self widgetTextureFromArray: object screen: scr];
  [self setWidgetColor: texture screen: scr];
  object = [defaults objectForKey: WMDIconBack];
  texture = [self textureFromArray: object screen: scr];
  [self setIconTile: texture screen: scr];

  object = [defaults objectForKey: WMDFTitleBack];
  texture = [self textureFromArray: object screen: scr];
  [self setFTitleBack: texture screen: scr];

  object = [defaults objectForKey: WMDPTitleBack];
  texture = [self textureFromArray: object screen: scr];
  [self setPTitleBack: texture screen: scr];

  object = [defaults objectForKey: WMDUTitleBack];
  texture = [self textureFromArray: object screen: scr];
  [self setUTitleBack: texture screen: scr];

  object = [defaults objectForKey: WMDResizebarBack];
  texture = [self textureFromArray: object screen: scr];
  [self setResizebarBack: texture screen: scr];

  object = [defaults objectForKey: WMDMenuTitleBack];
  texture = [self textureFromArray: object screen: scr];
  [self setMenuTitleBack: texture screen: scr];

  object = [defaults objectForKey: WMDMenuTextBack];
  texture = [self textureFromArray: object screen: scr];
  [self setMenuTextBack: texture screen: scr];

  object = [defaults objectForKey: WMDWorkspaceBack];
  [self setWorkspaceBack: object screen: scr];
}

- (void) readStaticDefaults
{
  /** read static default into wPreferences */
  BOOL boolValue;
  NSString *stringValue;

  /* default 4 */
  wPreferences.cmap_size = [defaults integerForKey: WMDColormapSize];
  if (wPreferences.cmap_size == 0)
    wPreferences.cmap_size = 4;

  /* default NO */
  wPreferences.no_dithering = [defaults boolForKey: WMDDisableDithering];

  /* default 64 */
  wPreferences.icon_size = [defaults integerForKey: WMDIconSize];
  if (wPreferences.icon_size == 0)
    wPreferences.icon_size = 64;

  /* default Mod1 */
  unsigned int mask;
  stringValue = [defaults stringForKey: WMDModifierKey];
  if (stringValue == nil)
    stringValue = @"Mod1";
  mask = wXModifierFromKey((char*)[stringValue cString]);
  if (mask < 0)
  {
    NSLog(@"Warning: modifier key %@ is not valid", stringValue);
  }
  wPreferences.modifier_mask = mask;

  /* default NO */
  wPreferences.disable_root_mouse = [defaults boolForKey: WMDDisableWSMouseActions];

  /* default NO */
  wPreferences.new_style = [defaults boolForKey: WMDNewStyle];

  /* default NO */
  boolValue = [defaults boolForKey: WMDDisableDock];
  wPreferences.flags.nodock = wPreferences.flags.nodock || boolValue;
  
  /* default NO */
  boolValue = [defaults boolForKey: WMDDisableClip];
  wPreferences.flags.noclip = wPreferences.flags.noclip || boolValue;

  /* default NO */
  wPreferences.disable_miniwindows = [defaults boolForKey: WMDDisableMiniwindows];

}


- (NSArray *) fallbackWMs
{
  return fallbackWMs;
}

/** Private **/

- (void) bind: (int) keybind withKey: (NSString *) key screen: (WScreen *) scr
{
  WShortKey shortcut;
  KeySym ksym;

  shortcut.keycode = 0;
  shortcut.modifier = 0;
  
  /** getKeybind() in defaults.c **/
  if ((key == nil) || [key isEqualToString: @"None"])
  {
  }
  else
  {
    NSMutableArray *keys = [NSMutableArray arrayWithArray: [key componentsSeparatedByString: @"+"]];
    if ([keys count] > 0)
    {
      ksym = XStringToKeysym((char*)[[keys lastObject] cString]);
      if (ksym == NoSymbol)
      {
        NSLog(@"Warning: invalid kbd shortcut specification %@", key);
	return;
      }
      shortcut.keycode = XKeysymToKeycode(dpy, ksym);
      if (shortcut.keycode == 0)
      {
        NSLog(@"Warning: invalid key in shortcut %@", key);
	return;
      }

      [keys removeLastObject];

      NSEnumerator *e = [keys objectEnumerator];
      NSString *modString;
      int mod;
      while ((modString = [e nextObject]))
      {
        mod = wXModifierFromKey((char*)[modString cString]);
	if (mod<0) {
	  NSLog(@"Warning: invalid key modifier %@", modString);
          return;
	}
	shortcut.modifier |= mod;
      }
    }
  }
  
  /** setKeyGrab() in defaults **/
  wKeyBindings[keybind] = shortcut;

  WWindow *wwin = scr->focused_window;

  while (wwin != NULL)
  {
    XUngrabKey(dpy, AnyKey, AnyModifier, wwin->frame->core->window);

    if (!WFLAGP(wwin, no_bind_keys))
    {
      wWindowSetKeyGrabs(wwin);
    }
    wwin = wwin->prev;
  }
}

/*** from defaults.c ***/
# include <X11/cursorfont.h>
typedef struct
{
    char *name;
    int id;
} WCursorLookup;

#define CURSOR_ID_NONE  (XC_num_glyphs)

static WCursorLookup cursor_table[] =
{
  { "X_cursor",               XC_X_cursor },
  { "arrow",                  XC_arrow },
  { "based_arrow_down",       XC_based_arrow_down },
  { "based_arrow_up",         XC_based_arrow_up },
  { "boat",                   XC_boat },
  { "bogosity",               XC_bogosity },
  { "bottom_left_corner",     XC_bottom_left_corner },
  { "bottom_right_corner",    XC_bottom_right_corner },
  { "bottom_side",            XC_bottom_side },
  { "bottom_tee",             XC_bottom_tee },
  { "box_spiral",             XC_box_spiral },
  { "center_ptr",             XC_center_ptr },
  { "circle",                 XC_circle },
  { "clock",                  XC_clock },
  { "coffee_mug",             XC_coffee_mug },
  { "cross",                  XC_cross },
  { "cross_reverse",          XC_cross_reverse },
  { "crosshair",              XC_crosshair },
  { "diamond_cross",          XC_diamond_cross },
  { "dot",                    XC_dot },
  { "dotbox",                 XC_dotbox },
  { "double_arrow",           XC_double_arrow },
  { "draft_large",            XC_draft_large },
  { "draft_small",            XC_draft_small },
  { "draped_box",             XC_draped_box },
  { "exchange",               XC_exchange },
  { "fleur",                  XC_fleur },
  { "gobbler",                XC_gobbler },
  { "gumby",                  XC_gumby },
  { "hand1",                  XC_hand1 },
  { "hand2",                  XC_hand2 },
  { "heart",                  XC_heart },
  { "icon",                   XC_icon },
  { "iron_cross",             XC_iron_cross },
  { "left_ptr",               XC_left_ptr },
  { "left_side",              XC_left_side },
  { "left_tee",               XC_left_tee },
  { "leftbutton",             XC_leftbutton },
  { "ll_angle",               XC_ll_angle },
  { "lr_angle",               XC_lr_angle },
  { "man",                    XC_man },
  { "middlebutton",           XC_middlebutton },
  { "mouse",                  XC_mouse },
  { "pencil",                 XC_pencil },
  { "pirate",                 XC_pirate },
  { "plus",                   XC_plus },
  { "question_arrow",         XC_question_arrow },
  { "right_ptr",              XC_right_ptr },
  { "right_side",             XC_right_side },
  { "right_tee",              XC_right_tee },
  { "rightbutton",            XC_rightbutton },
  { "rtl_logo",               XC_rtl_logo },
  { "sailboat",               XC_sailboat },
  { "sb_down_arrow",          XC_sb_down_arrow },
  { "sb_h_double_arrow",      XC_sb_h_double_arrow },
  { "sb_left_arrow",          XC_sb_left_arrow },
  { "sb_right_arrow",         XC_sb_right_arrow },
  { "sb_up_arrow",            XC_sb_up_arrow },
  { "sb_v_double_arrow",      XC_sb_v_double_arrow },
  { "shuttle",                XC_shuttle },
  { "sizing",                 XC_sizing },
  { "spider",                 XC_spider },
  { "spraycan",               XC_spraycan },
  { "star",                   XC_star },
  { "target",                 XC_target },
  { "tcross",                 XC_tcross },
  { "top_left_arrow",         XC_top_left_arrow },
  { "top_left_corner",        XC_top_left_corner },
  { "top_right_corner",       XC_top_right_corner },
  { "top_side",               XC_top_side },
  { "top_tee",                XC_top_tee },
  { "trek",                   XC_trek },
  { "ul_angle",               XC_ul_angle },
  { "umbrella",               XC_umbrella },
  { "ur_angle",               XC_ur_angle },
  { "watch",                  XC_watch },
  { "xterm",                  XC_xterm },
  { NULL,                     CURSOR_ID_NONE }
};

#if 0 // FIXME: need work
static void
check_bitmap_status(int status, char *filename, Pixmap bitmap)
{
  switch(status) {
    case BitmapOpenFailed:
      wwarning(("failed to open bitmap file \"%s\""), filename);
      break;
    case BitmapFileInvalid:
      wwarning(("\"%s\" is not a valid bitmap file"), filename);
      break;
    case BitmapNoMemory:
      wwarning(("out of memory reading bitmap file \"%s\""), filename);
      break;
    case BitmapSuccess:
      XFreePixmap(dpy, bitmap);
      break;
  }
}
#endif

/** from parse_cursor() in defaults **/

/*
 * (none)
 * (builtin, <cursor_name>)
 * (bitmap, <cursor_bitmap>, <cursor_mask>)
 */
- (Cursor) cursorFromArray: (NSArray *) array
{
  int i, type = [array count];
  int cursor_id = CURSOR_ID_NONE;
  switch(type) {
    case 1:
      // Must be none
      return None;
    case 2:
      // Must be builtin
      if ([[array objectAtIndex: 0] isEqualToString: @"builtin"] == NO)
      {
	return None;
      }
      char *val = (char*)[[array objectAtIndex: 1] cString];
      for(i = 0; NULL != cursor_table[i].name; i++) {
	if (0 == strcasecmp(val, cursor_table[i].name))
	{
	  cursor_id = cursor_table[i].id;
	  break;
	}
      }
      if (CURSOR_ID_NONE == cursor_id) {
	NSLog(@"Warning: unknown builtin cursor name %s", val);
	return None;
      }	else {	
	return XCreateFontCursor(dpy, cursor_id);
      }
    case 3:
      /* bitmap */
#if 0 // FIXME: need work
      char *bitmap_name;
      char *mask_name;
      int bitmap_status;
      int mask_status;
      Pixmap bitmap;
      Pixmap mask;
      unsigned int w, h;
      int x, y;
      XColor fg, bg;

      if (3 != nelem) {
         wwarning(("bad number of arguments in cursor specification"));
         return(status);
      }
      elem = WMGetFromPLArray(pl, 1);
      if (!elem || !WMIsPLString(elem)) {
         return(status);
      }
      val = WMGetFromPLString(elem);
      bitmap_name = FindImage(wPreferences.pixmap_path, val);
      if (!bitmap_name) {
        wwarning(("could not find cursor bitmap file \"%s\""), val);
        return(status);
      }
      elem = WMGetFromPLArray(pl, 2);
      if (!elem || !WMIsPLString(elem)) {
        wfree(bitmap_name);
        return(status);
      }
      val = WMGetFromPLString(elem);
      mask_name = FindImage(wPreferences.pixmap_path, val);
      if (!mask_name) {
        wfree(bitmap_name);
        wwarning(("could not find cursor bitmap file \"%s\""), val);
        return(status);
      }
      mask_status = XReadBitmapFile(dpy, scr->w_win, mask_name, &w, &h,
                                    &mask, &x, &y);
      bitmap_status = XReadBitmapFile(dpy, scr->w_win, bitmap_name, &w, &h,
                                      &bitmap, &x, &y);
      if ((BitmapSuccess == bitmap_status) &&
          (BitmapSuccess == mask_status)) {
         fg.pixel = scr->black_pixel;
         bg.pixel = scr->white_pixel;
         XQueryColor(dpy, scr->w_colormap, &fg);
         XQueryColor(dpy, scr->w_colormap, &bg);
         *cursor = XCreatePixmapCursor(dpy, bitmap, mask, &fg, &bg, x, y);
         status = 1;
      }
      check_bitmap_status(bitmap_status, bitmap_name, bitmap);
      check_bitmap_status(mask_status, mask_name, mask);
      wfree(bitmap_name);
      wfree(mask_name);
    }
    return(status);
#endif
      return None;
    default:
      NSLog(@"Warning: bad number of arguments in cursor specification");
      return None;
  }
}

- (void) bind: (int) index withCursor: (NSArray *) array
                                screen: (WScreen *) scr
{
  /* string cannot be nil because a defaul is register inside already (-init) */
  if (array == nil)
  {
    NSLog(@"Error: system error in WMDefault");
    return;
  }
#if 0 // FIXME: weird, this doesn't work
  else if ([array isKindOfClass: [NSArray class]] == NO);
  {
    NSLog(@"Warning: wrong option format for cursor %@", array);
    return;
  }
#endif
  static Cursor cursor;
  cursor  = [self cursorFromArray: array];
  if (cursor == None)
  {
    NSLog(@"Warning: error in cursor specification %@", array);
    return;
  }

  if (wCursor[index] != None) {
    XFreeCursor(dpy, wCursor[index]);
  }

  wCursor[index] = cursor;

  if (index==WCUR_ROOT && cursor!=None)
  {
    XDefineCursor(dpy, scr->root_win, cursor);
  }
}

/** getPathList() **/
- (char *) pathList: (NSArray *) array
{
  if ((array == nil) || ([array count] == 0))
  {
    return NULL;
  }
  else
  {
    /* put everything together with `:' */
    NSMutableString *ms = [[NSMutableString alloc] init];
    int i, count = [array count];
    for (i = 0; i < count; i++)
    {
      if (i)
	[ms appendString: @":"];
      [ms appendString: [array objectAtIndex: i]];
    }
    /* use wmalloc */
    int len = [ms length];
    char *data = wmalloc(len+1);
    strcpy(data, (char*)[ms cString]);
    return data;
  }
}

- (WCoord) coordFromPoint: (NSValue *) point screen: (WScreen *) scr
{
  static WCoord data;
  data.x = 0;
  data.y = 0;
  NSPoint p = [point pointValue];
  if (point)
  {
    if (p.x < 0)
      data.x = 0;
    else if (p.x > scr->scr_width/3)
      data.x = scr->scr_width/3;
    else
      data.x = p.x;

    if (p.y < 0)
      data.y = 0;
    else if (p.y > scr->scr_height/3)
      data.y = scr->scr_width/3;
    else
      data.y = p.y;
  }
  return data;
}

- (void) updateUsableArea: (WScreen *) scr
{
  wScreenUpdateUsableArea(scr);
}

- (XColor *) colorFromString: (NSString *) string screen: (WScreen *) scr
{
  static XColor color;
  char *val = (char*)[string cString];
  if (!wGetColor(scr, val, &color)) 
  {
    NSLog(@"Warning: could not get color from %@", string);
  }
  return &color;
}

- (void) setHighlight: (XColor *) color screen: (WScreen *) scr
{
  if (scr->select_color)
    WMReleaseColor(scr->select_color);

  scr->select_color =
    WMCreateRGBColor(scr->wmscreen, color->red, color->green,
                     color->blue, True);

  wFreeColor(scr, color->pixel);
}

- (void) setHighlightText: (XColor *) color screen: (WScreen *) scr
{
  if (scr->select_text_color)
    WMReleaseColor(scr->select_text_color);

  scr->select_text_color =
    WMCreateRGBColor(scr->wmscreen, color->red, color->green,
                     color->blue, True);

  wFreeColor(scr, color->pixel);
}

- (void) setClipTitle: (int) index color: (XColor *) color
               screen: (WScreen *) scr
{
  if (scr->clip_title_color[index])
    WMReleaseColor(scr->clip_title_color[index]);
  scr->clip_title_color[index] = WMCreateRGBColor(scr->wmscreen, color->red,
                                                  color->green, color->blue,
                                                  True);
#ifdef GRADIENT_CLIP_ARROW
  if (index == CLIP_NORMAL) {
    RImage *image;
    RColor color1, color2;
    int pt = CLIP_BUTTON_SIZE*wPreferences.icon_size/64;
    int as = pt - 15; /* 15 = 5+5+5 */

    FREE_PIXMAP(scr->clip_arrow_gradient);

    color1.red = (color->red >> 8)*6/10;
    color1.green = (color->green >> 8)*6/10;
    color1.blue = (color->blue >> 8)*6/10;

    color2.red = WMIN((color->red >> 8)*20/10, 255);
    color2.green = WMIN((color->green >> 8)*20/10, 255);
    color2.blue = WMIN((color->blue >> 8)*20/10, 255);

    image = RRenderGradient(as+1, as+1, &color1, &color2, RDiagonalGradient);
    RConvertImage(scr->rcontext, image, &scr->clip_arrow_gradient);
    RReleaseImage(image);
  }
#endif /* GRADIENT_CLIP_ARROW */

  wFreeColor(scr, color->pixel);
}

- (void) setWindowTitle: (int) index color: (XColor *) color
                 screen: (WScreen *) scr
{
  if (scr->window_title_color[index])
    WMReleaseColor(scr->window_title_color[index]);

  scr->window_title_color[index] =
    WMCreateRGBColor(scr->wmscreen, color->red, color->green, color->blue,
                     True);

  wFreeColor(scr, color->pixel);
}

- (void) setMenuTitle: (XColor *) color
         screen: (WScreen *) scr
{
  if (scr->menu_title_color[0])
    WMReleaseColor(scr->menu_title_color[0]);

  scr->menu_title_color[0] =
    WMCreateRGBColor(scr->wmscreen, color->red, color->green,
                     color->blue, True);

  wFreeColor(scr, color->pixel);
}

- (void) setMenuText: (XColor *) color
	 screen: (WScreen *) scr
{
  if (scr->mtext_color)
    WMReleaseColor(scr->mtext_color);

  scr->mtext_color = WMCreateRGBColor(scr->wmscreen, color->red,
                                      color->green, color->blue, True);

  if (WMColorPixel(scr->dtext_color) == WMColorPixel(scr->mtext_color)) {
    WMSetColorAlpha(scr->dtext_color, 0x7fff);
  } else {
    WMSetColorAlpha(scr->dtext_color, 0xffff);
  }

  wFreeColor(scr, color->pixel);
}

- (void) setMenuDisabled: (XColor *) color
         screen: (WScreen *) scr
{
  if (scr->dtext_color)
    WMReleaseColor(scr->dtext_color);

  scr->dtext_color = WMCreateRGBColor(scr->wmscreen, color->red,
                                      color->green, color->blue, True);

  if (WMColorPixel(scr->dtext_color) == WMColorPixel(scr->mtext_color)) {
    WMSetColorAlpha(scr->dtext_color, 0x7fff);
  } else {
    WMSetColorAlpha(scr->dtext_color, 0xffff);
  }

  wFreeColor(scr, color->pixel);
}

- (void) setIconTitleColor: (XColor *) color 
               screen: (WScreen *) scr
{
  if (scr->icon_title_color)
    WMReleaseColor(scr->icon_title_color);
  scr->icon_title_color = WMCreateRGBColor(scr->wmscreen, color->red,
                                           color->green, color->blue,
                                           True);

  wFreeColor(scr, color->pixel);
}

- (void) setIconTitleBack: (XColor *) color 
               screen: (WScreen *) scr
{
  if (scr->icon_title_texture) {
    wTextureDestroy(scr, (WTexture*)scr->icon_title_texture);
  }
  scr->icon_title_texture = wTextureMakeSolid(scr, color);
}

- (WMFont *) fontFromString: (NSString *) stringValue screen: (WScreen *) scr
{
  static WMFont *font;
  char *val = (char*)[stringValue cString];;

  font = WMCreateFont(scr->wmscreen, val);
  if (!font)
    font = WMCreateFont(scr->wmscreen, "fixed");

  if (!font) {
    NSLog(@"Fatal: could not load any usable font !!!");
    exit(1);
  }
  return font;
}

- (void) setWinTitleFont: (WMFont *) font screen: (WScreen *) scr
{
  if (scr->title_font) {
    WMReleaseFont(scr->title_font);
  }
  scr->title_font = font;
}

- (void) setMenuTitleFont: (WMFont *) font screen: (WScreen *) scr
{
  if (scr->menu_title_font) {
    WMReleaseFont(scr->menu_title_font);
  }
  scr->menu_title_font = font;
}

- (void) setMenuTextFont: (WMFont *) font screen: (WScreen *) scr
{
  if (scr->menu_entry_font) {
    WMReleaseFont(scr->menu_entry_font);
  }
  scr->menu_entry_font = font;
}

- (void) setIconTitleFont: (WMFont *) font screen: (WScreen *) scr
{
  if (scr->icon_title_font) {
    WMReleaseFont(scr->icon_title_font);
  }
  scr->icon_title_font = font;
}

- (void) setClipTitleFont: (WMFont *) font screen: (WScreen *) scr
{
  if (scr->clip_title_font) {
    WMReleaseFont(scr->clip_title_font);
  }
  scr->clip_title_font = font;
}

- (void) setLargeDisplayFont: (WMFont *) font screen: (WScreen *) scr
{
  if (scr->workspace_name_font) {
    WMReleaseFont(scr->workspace_name_font);
  }
  scr->workspace_name_font = font;
}

- (WTexture *) widgetTextureFromArray: (NSArray *) a screen: (WScreen *) scr
{
  if ([[a objectAtIndex: 0] isEqualToString: @"solid"] == NO)
  {
    NSLog(@"Warning: Wrong option for WidgetTexture: %@", a);
  }

  return [self textureFromArray: a screen: scr];
}

- (WTexture *) textureFromArray: (NSArray *) a screen: (WScreen *) scr
{
  static WTexture *texture;

  texture = [self parseTexture: a screen: scr];

  return texture;
}

- (void) setWidgetColor: (WTexture *) texture screen: (WScreen *) scr
{
  if (scr->widget_texture) {
    wTextureDestroy(scr, (WTexture *)scr->widget_texture);
  }
  scr->widget_texture = (WTexSolid *)texture;
}

/** FIXME: only work for solid now. Need to make other texture work. */
- (WTexture *) parseTexture: (NSArray *) array screen: (WScreen *) scr
{
  char *val;
  WTexture *texture=NULL;

  if ([array count] < 2)
    return NULL;

  if ([[array objectAtIndex: 0] isEqualToString: @"solid"]) {
    XColor color;
    if ([array count] != 2)
      return NULL;

    /* get color */
    val = (char*)[[array objectAtIndex: 1] cString];

    if (!XParseColor(dpy, scr->w_colormap, val, &color)) {
      NSLog(@"%s is not a valid color name", val);
      return NULL;
    }

    texture = (WTexture*)wTextureMakeSolid(scr, &color);
  }
  return texture;
}

- (void) setIconTile: (WTexture *) texture screen: (WScreen *) scr
{
  Pixmap pixmap;
  RImage *img;
  int reset = 0;

  img = wTextureRenderImage(texture, wPreferences.icon_size,
                            wPreferences.icon_size,
                            (texture->any.type & WREL_BORDER_MASK)
                            ? WREL_ICON : WREL_FLAT);
  if (!img) {
    NSLog((@"could not render texture for icon background"));
    wTextureDestroy(scr, texture);
    return;
  }
  RConvertImage(scr->rcontext, img, &pixmap);

  if (scr->icon_tile) {
    reset = 1;
    RReleaseImage(scr->icon_tile);
    XFreePixmap(dpy, scr->icon_tile_pixmap);
  }
  scr->icon_tile = img;

  /* put the icon in the noticeboard hint */
  PropSetIconTileHint(scr, img);

  if (!wPreferences.flags.noclip) {
    if (scr->clip_tile) {
      RReleaseImage(scr->clip_tile);
    }
    scr->clip_tile = wClipMakeTile(scr, img);
  }

  scr->icon_tile_pixmap = pixmap;

  if (scr->def_icon_pixmap) {
    XFreePixmap(dpy, scr->def_icon_pixmap);
    scr->def_icon_pixmap = None;
  }

  if (scr->def_ticon_pixmap) {
    XFreePixmap(dpy, scr->def_ticon_pixmap);
    scr->def_ticon_pixmap = None;
  }

  if (scr->icon_back_texture) {
    wTextureDestroy(scr, (WTexture*)scr->icon_back_texture);
  }
  scr->icon_back_texture = wTextureMakeSolid(scr, &(texture->any.color));

  if (scr->clip_balloon)
    XSetWindowBackground(dpy, scr->clip_balloon,
                         texture->any.color.pixel);

  wTextureDestroy(scr, texture);
}

- (void) setFTitleBack: (WTexture *) texture screen: (WScreen *) scr
{
  if (scr->window_title_texture[WS_FOCUSED]) {
    wTextureDestroy(scr, scr->window_title_texture[WS_FOCUSED]);
  }
  scr->window_title_texture[WS_FOCUSED] = texture;
}

- (void) setPTitleBack: (WTexture *) texture screen: (WScreen *) scr
{
  if (scr->window_title_texture[WS_PFOCUSED]) {
    wTextureDestroy(scr, scr->window_title_texture[WS_PFOCUSED]);
  }
  scr->window_title_texture[WS_PFOCUSED] = texture;
}

- (void) setUTitleBack: (WTexture *) texture screen: (WScreen *) scr
{
  if (scr->window_title_texture[WS_UNFOCUSED]) {
    wTextureDestroy(scr, scr->window_title_texture[WS_UNFOCUSED]);
  }
  scr->window_title_texture[WS_UNFOCUSED] = texture;
}

- (void) setResizebarBack: (WTexture *) texture screen: (WScreen *) scr
{
  if (scr->resizebar_texture[0]) {
    wTextureDestroy(scr, scr->resizebar_texture[0]);
  }
  scr->resizebar_texture[0] = texture;
}

- (void) setMenuTitleBack: (WTexture *) texture screen: (WScreen *) scr
{
  if (scr->menu_title_texture[0]) {
    wTextureDestroy(scr, scr->menu_title_texture[0]);
  }
  scr->menu_title_texture[0] = texture;
}

- (void) setMenuTextBack: (WTexture *) texture screen: (WScreen *) scr
{
  if (scr->menu_item_texture) {
    wTextureDestroy(scr, scr->menu_item_texture);
    wTextureDestroy(scr, (WTexture*)scr->menu_item_auxtexture);
  }
  scr->menu_item_texture = texture;
  scr->menu_item_auxtexture
    = wTextureMakeSolid(scr, &scr->menu_item_texture->any.color);
}

/*** background **/
- (BackgroundTexture *) parseTexture: (NSArray *) array 
                             context: (RContext *) rc 
			      screen: (WScreen *) scr
{
  if ([array count] < 2) 
    return NULL;

  BackgroundTexture *texture = NULL;
  texture = malloc(sizeof(BackgroundTexture));
  memset(texture, 0, sizeof(BackgroundTexture));

  if ([[array objectAtIndex: 0] isEqualToString: @"solid"])
  {
    XColor color;
    Pixmap pixmap;
    char *c;

    c = (char*)[[array objectAtIndex: 1] cString];

    texture->solid = 1;

    if (!XParseColor(dpy, DefaultColormap(dpy, scr->screen),
			    c, &color))
    {
      NSLog(@"Warning: could not parse color %@", array);
      free(texture);
      return NULL;
    }

    XAllocColor(dpy, scr->colormap, &color);

    pixmap = XCreatePixmap(dpy, scr->root_win, 8, 8, scr->depth);
    XSetForeground(dpy, DefaultGC(dpy, scr->screen), color.pixel);
    XFillRectangle(dpy, pixmap, DefaultGC(dpy, scr->screen), 0, 0, 8, 8);

    texture->pixmap = pixmap;
    texture->color = color;
    texture->width = 8;
    texture->height = 8;
  }

  return texture;
}

/* Support only solid and image, from wmsetbg.c */
/* Format: (solid, #color) or (center, #image_path, #color) */
- (void) setWorkspaceBack: (NSArray *) array screen: (WScreen *) scr
{
  RContext *rc;
  RContextAttributes rattr;
  BackgroundTexture *tex;
  id object;

  rattr.flags = RC_RenderMode | RC_ColorsPerChannel |
	        RC_StandardColormap | RC_DefaultVisual;
  rattr.render_mode = RDitheredRendering;
  rattr.colors_per_channel = 4;
  rattr.standard_colormap_mode = RCreateStdColormap;
  
  rc = RCreateContext(dpy, scr->screen, &rattr);

  if (!rc) {
    rattr.standard_colormap_mode = RIgnoreStdColormap;
    rc = RCreateContext(dpy, scr->screen, &rattr);
  }

  if (!rc) {
	  NSLog(@"Fatal: could not initialize wrlib: %s",
			  RMessageForError(RErrorCode));
	  exit(1);
  }

  object = [defaults objectForKey: WMDWorkspaceBack];
  tex = [self parseTexture: object context: rc screen: scr];
  if (tex == NULL)
    exit(1);

  if (tex->solid)
  {
    XSetWindowBackground(dpy, scr->root_win, tex->color.pixel);
  } else {
    XSetWindowBackground(dpy, scr->root_win, tex->pixmap);
  }
  XClearWindow(dpy, scr->root_win);

  XSync(dpy, False);

#if 0
  /** Not sure this is necessary */
  {
    Pixmap copyP;
    Display *tmpDpy;
    static Atom prop = 0;
    Atom type;
    int format;
    unsigned long length, after;
    unsigned char *data;
    int mode;

    /* must open a new display or the RetainPermanent will
     * leave stuff allocated in RContext unallocated after exit */
    tmpDpy = XOpenDisplay(dpy);
    if (!tmpDpy) {
      NSLog(@"could not open display to update background image information");
      copyP= None;
    } else {
      XSync(dpy, False);
      pixmap = XCreatePixmap(tmpDpy, scr->root_win, scr->scr_width, 
		      scr->scr_height, scr->w_depth);
      XCopyArea(tempDpy, pixmap, copyP, DefaultGC(tmpDpy, scr->screen),
		      0, 0, scr->scr_width, scr->scr_height, 0, 0);
      XSync(tmpDpy, False);

      XSetCloseDownMode(tmpDpy, RetainPermanent);
      XCloseDisplay(tmpDpy);
    }

    if (!prop) {
      prop = XInternAtom(dpy, "_XROOTPMAP_ID", False);
    }

    XGrabServer(dpy);
    /* Clear out the old pixmap */
    XGetWindowProperty(dpy, scr->root_win, prop, 0L, 1L, False,
		    AnyPropertyType, &type, &format, &length, &after,
		    &data);
    if ((type = XA_PIXMAP) && (format == 32) && (length == 1)) 
    {
      XSetErrorHandle(dummyErrorHandler);
      XKillClient(dpy, *((Pixmap *)data));
      XSync(dpy, False);
      XSetErrorHandle(NULL);
      mode = PropModeReplace;
    } else {
      mode = PropModeAppend;
    }

    if (copyP)
    {
      XChangeProperty(dpy, scr->root_win, prop, XA_PIXMAP, 32, mode,
		      (unsigned char *) &pixmap, 1);
    }
    else
    {
      XDeleteProperty(dpy, scr->root_win, prop);
    }

    XUngrabServer(dpy);
    XFlush(dpy);
  }
#endif
}

- (void) synchronize
{
  [defaults setObject: wa forKey: WDWindowAttributes];
  [defaults setObject: ws forKey: WDSessionStates];
  [defaults synchronize];
}

/** Window attributes **/
- (NSDictionary *) windowAttributes
{
  return wa;
}

- (NSDictionary *) attributesForWindow: (NSString *) name
{
  return AUTORELEASE([[wa objectForKey: name] copy]);
}

- (id) objectForKey: (id) key window: (NSString *) name
{
  return AUTORELEASE([[(NSDictionary *)[wa objectForKey: name] objectForKey: key] copy]);
}

- (void) setObject: (id) object forKey: (NSString *) key
				window: (NSString *) name
{
  NSDictionary *d = [wa objectForKey: name];
  NSMutableDictionary *dict;
  if (d)
  {
    dict = [NSMutableDictionary dictionaryWithDictionary: d];
  }
  else
  {
    dict = AUTORELEASE([[NSMutableDictionary alloc] init]);
  }
  [dict setObject: AUTORELEASE([object copy]) forKey: AUTORELEASE([key copy])];
  [wa setObject: dict forKey: name];
}

- (void) removeObjectForKey: (id) key window: (NSString *) name
{
  NSDictionary *d = [wa objectForKey: name];
  NSMutableDictionary *dict;
  if (d)
  {
    dict = [NSMutableDictionary dictionaryWithDictionary: d];
  }
  else
  {
    dict = AUTORELEASE([[NSMutableDictionary alloc] init]);
  }
  [dict removeObjectForKey: AUTORELEASE([key copy])];
  [wa setObject: dict forKey: name];
}

- (void) removeWindow: (NSString *) name
{
  [wa removeObjectForKey: name];
}

- (void) setAttributes: (NSDictionary *) dict window: (NSString *) name
{
  [wa setObject: dict forKey: name];
}

/** sessions **/
- (NSDictionary *) sessionStates
{
  return ws;
}

- (NSDictionary *) sessionStatesForScreen: (int) screen
{
  NSDictionary *dict = [ws objectForKey: [NSString stringWithFormat: @"%d", screen]];
  if (dict)
    return AUTORELEASE([dict copy]);
  else
    return AUTORELEASE([[NSDictionary alloc] init]);
}

- (void) setSessionStates: (NSDictionary *) dict forScreen: (int) screen
{
  [ws setObject: dict forKey: [NSString stringWithFormat: @"%d", screen]];
}

/* workspace attributes for screen */
- (NSArray *) workspacesForScreen: (int) screen
{
  NSDictionary *dict = [self sessionStatesForScreen: screen];
  id object = [dict objectForKey: WSWorkspaces];
  if (object)
    return AUTORELEASE([object copy]);
  else
    return nil;
}

- (void) setWorkspaces: (NSArray *) array forScreen: (int) screen
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self sessionStatesForScreen: screen]]; 
  [dict setObject: array forKey: WSWorkspaces];
  [self setSessionStates: dict forScreen: screen];
}

/* dock attributes for screen */
- (NSDictionary *) dockForScreen: (int) screen
{
  NSDictionary *dict = [self sessionStatesForScreen: screen];
  id object = [dict objectForKey: WSDock];
  if (object)
    return AUTORELEASE([object copy]);
  else
    return nil;
}

- (void) setDock: (NSDictionary *) d forScreen: (int) screen
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self sessionStatesForScreen: screen]]; 
  [dict setObject: d forKey: WSDock];
  [self setSessionStates: dict forScreen: screen];
}

/* clip attributes for screen */
- (NSDictionary *) clipForScreen: (int) screen
{
  NSDictionary *dict = [self sessionStatesForScreen: screen];
  id object = [dict objectForKey: WSClip];
  if (object)
    return AUTORELEASE([object copy]);
  else
    return nil;
}

- (void) setClip: (NSDictionary *) d forScreen: (int) screen
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self sessionStatesForScreen: screen]]; 
  [dict setObject: d forKey: WSClip];
  [self setSessionStates: dict forScreen: screen];
}

/* applicatios */
- (NSArray *) applicationsForScreen: (int) screen
{
  NSDictionary *dict = [self sessionStatesForScreen: screen];
  id object = [dict objectForKey: WSApplications];
  if (object)
    return AUTORELEASE([object copy]);
  else
    return nil;
}

- (void) setApplications: (NSArray *) a forScreen: (int) screen
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self sessionStatesForScreen: screen]]; 
  [dict setObject: a forKey: WSApplications];
  [self setSessionStates: dict forScreen: screen];
}

- (void) removeApplicationsForScreen: (int) screen
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self sessionStatesForScreen: screen]]; 
  [dict removeObjectForKey: WSApplications];
  [self setSessionStates: dict forScreen: screen];
}

/* workspace */
- (NSString *) workspaceForScreen: (int) screen
{
  NSDictionary *dict = [self sessionStatesForScreen: screen];
  id object = [dict objectForKey: WSWorkspace];
  if (object)
    return AUTORELEASE([object copy]);
  else
    return nil;
}

- (void) setWorkspace: (NSString *) string forScreen: (int) screen
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self sessionStatesForScreen: screen]]; 
  [dict setObject: string forKey: WSWorkspace];
  [self setSessionStates: dict forScreen: screen];
}

- (void) removeWorkspaceForScreen: (int) screen
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self sessionStatesForScreen: screen]]; 
  [dict removeObjectForKey: WSWorkspace];
  [self setSessionStates: dict forScreen: screen];
}

@end
