

#ifndef _WINGS_H_
#define _WINGS_H_

#include <wraster.h>
#include <WINGs/WUtil.h>
#include <X11/Xlib.h>

#define WINGS_H_VERSION  20041030


#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */
#if 0
}
#endif


typedef unsigned long WMPixel;


typedef struct {
    unsigned int width;
    unsigned int height;
} WMSize;

typedef struct {
    int x;
    int y;
} WMPoint;

typedef struct {
    WMPoint pos;
    WMSize size;
} WMRect;





#define ClientMessageMask	(1L<<30)


#ifndef _DEFINED_GNUSTEP_WINDOW_INFO
#define	_DEFINED_GNUSTEP_WINDOW_INFO
/*
 * Window levels are taken from GNUstep (gui/AppKit/NSWindow.h)
 * NSDesktopWindowLevel intended to be the level at which things
 * on the desktop sit ... so you should be able
 * to put a desktop background just below it.
 *
 * Applications are actually permitted to use any value in the
 * range INT_MIN+1 to INT_MAX
 */
enum {
    WMDesktopWindowLevel = -1000, /* GNUstep addition     */
    WMNormalWindowLevel = 0,
    WMFloatingWindowLevel = 3,
    WMSubmenuWindowLevel = 3,
    WMTornOffMenuWindowLevel = 3,
    WMMainMenuWindowLevel = 20,
    WMDockWindowLevel = 21,       /* Deprecated - use NSStatusWindowLevel */
    WMStatusWindowLevel = 21,
    WMModalPanelWindowLevel = 100,
    WMPopUpMenuWindowLevel = 101,
    WMScreenSaverWindowLevel = 1000
};


/* window attributes */
enum {
    WMBorderlessWindowMask = 0,
    WMTitledWindowMask = 1,
    WMClosableWindowMask = 2,
    WMMiniaturizableWindowMask = 4,
    WMResizableWindowMask = 8,
    WMIconWindowMask = 64,
    WMMiniWindowMask = 128
};
#endif


/* button types */
typedef enum {
    /* 0 is reserved for internal use */
    WBTMomentaryPush = 1,
    WBTPushOnPushOff = 2,
    WBTToggle = 3,
    WBTSwitch = 4,
    WBTRadio = 5,
    WBTMomentaryChange = 6,
    WBTOnOff = 7,
    WBTMomentaryLight = 8
} WMButtonType;

/* button behaviour masks */
enum {
    WBBSpringLoadedMask = (1 << 0),
    WBBPushInMask       = (1 << 1),
    WBBPushChangeMask   = (1 << 2),
    WBBPushLightMask    = (1 << 3),
    WBBStateLightMask   = (1 << 5),
    WBBStateChangeMask  = (1 << 6),
    WBBStatePushMask    = (1 << 7)
};


/* frame title positions */
typedef enum {
    WTPNoTitle,
    WTPAboveTop,
    WTPAtTop,
    WTPBelowTop,
    WTPAboveBottom,
    WTPAtBottom,
    WTPBelowBottom
} WMTitlePosition;


/* relief types */
typedef enum {
    WRFlat,
    WRSimple,
    WRRaised,
    WRSunken,
    WRGroove,
    WRRidge,
    WRPushed
} WMReliefType;


/* alignment types */
typedef enum {
    WALeft,
    WACenter,
    WARight,
    WAJustified		       /* not valid for textfields */
} WMAlignment;


/* image position */
typedef enum {
    WIPNoImage,
    WIPImageOnly,
    WIPLeft,
    WIPRight,
    WIPBelow,
    WIPAbove,
    WIPOverlaps
} WMImagePosition;

/* text movement types */
enum {
    WMIllegalTextMovement,
    WMReturnTextMovement,
    WMEscapeTextMovement,
    WMTabTextMovement,
    WMBacktabTextMovement,
    WMLeftTextMovement,
    WMRightTextMovement,
    WMUpTextMovement,
    WMDownTextMovement
};

/* text field special events */
enum {
    WMInsertTextEvent,
    WMDeleteTextEvent
};

/* drag operations */
typedef enum {
    WDOperationNone = 0,
    WDOperationCopy,
    WDOperationMove,
    WDOperationLink,
    WDOperationAsk,
    WDOperationPrivate
} WMDragOperationType;


/* system images */
#define WSIReturnArrow			1
#define WSIHighlightedReturnArrow	2
#define WSIScrollerDimple		3
#define WSIArrowLeft			4
#define WSIHighlightedArrowLeft	        5
#define WSIArrowRight			6
#define WSIHighlightedArrowRight	7
#define WSIArrowUp			8
#define WSIHighlightedArrowUp		9
#define WSIArrowDown			10
#define WSIHighlightedArrowDown		11
#define WSICheckMark			12

enum {
    WLDSSelected = (1 << 16),
    WLDSDisabled = (1 << 17),
    WLDSFocused = (1 << 18),
    WLDSIsBranch = (1 << 19)
};

/* alert panel return values */
enum {
    WAPRDefault = 0,
    WAPRAlternate = 1,
    WAPROther = -1,
    WAPRError = -2
};



/* types of input observers */
enum {
    WIReadMask = (1 << 0),
    WIWriteMask = (1 << 1),
    WIExceptMask = (1 << 2)
};



typedef int W_Class;

enum {
    WC_Window = 0,
    WC_Frame = 1,
    WC_Label = 2,
    WC_Button = 3,
    WC_TextField = 4,
    WC_PopUpButton = 9,
    WC_MenuView = 16,
    WC_Box = 19
};

/* All widgets must start with the following structure
 * in that order. Used for typecasting to get some generic data */
typedef struct W_WidgetType {
    W_Class widgetClass;
    struct W_View *view;

} W_WidgetType;


#define WMWidgetClass(widget)  	(((W_WidgetType*)(widget))->widgetClass)
#define WMWidgetView(widget)   	(((W_WidgetType*)(widget))->view)


/* widgets */

typedef void WMWidget;

typedef struct W_Pixmap WMPixmap;
typedef struct W_Font	WMFont;
typedef struct W_Color	WMColor;

typedef struct W_Screen WMScreen;

typedef struct W_View WMView;

typedef struct W_Window WMWindow;
typedef struct W_Frame WMFrame;
typedef struct W_Button WMButton;
typedef struct W_Label WMLabel;
typedef struct W_PopUpButton WMPopUpButton;
typedef struct W_Box WMBox;


/* not widgets */
typedef struct W_MenuItem WMMenuItem;

/* struct for message panel */
typedef struct WMAlertPanel {
    WMWindow *win;		       /* window */
    WMBox *vbox;
    WMBox *hbox;
    WMButton *defBtn;		       /* default button */
    WMButton *altBtn;		       /* alternative button */
    WMButton *othBtn;		       /* other button */
    WMLabel *iLbl;		       /* icon label */
    WMLabel *tLbl;		       /* title label */
    WMLabel *mLbl;		       /* message label */
    WMFrame *line;		       /* separator */
    short result;		       /* button that was pushed */
} WMAlertPanel;

/* Basic font styles. Used to easily get one style from another */
typedef enum WMFontStyle {
    WFSNormal = 0,
    WFSBold   = 1,
    WFSItalic = 2,
    WFSBoldItalic = 3
} WMFontStyle;


typedef void WMEventProc(XEvent *event, void *clientData);

typedef void WMEventHook(XEvent *event);

/* self is set to the widget from where the callback is being called and
 * clientData to the data set to with WMSetClientData() */
typedef void WMAction(WMWidget *self, void *clientData);

/* same as WMAction, but for stuff that arent widgets */
typedef void WMAction2(void *self, void *clientData);

typedef void WMSelectionCallback(WMView *view, Atom selection, Atom target,
                                 Time timestamp, void *cdata, WMData *data);


typedef struct WMSelectionProcs {
    WMData* (*convertSelection)(WMView *view, Atom selection, Atom target,
                                void *cdata, Atom *type);
    void (*selectionLost)(WMView *view, Atom selection, void *cdata);
    void (*selectionDone)(WMView *view, Atom selection, Atom target,
                          void *cdata);
} WMSelectionProcs;


typedef struct W_DraggingInfo WMDraggingInfo;


/* links a label to a dnd operation. */
typedef struct W_DragOperationtItem WMDragOperationItem;


typedef struct W_DragSourceProcs {
    WMArray* (*dropDataTypes)(WMView *self);
    WMDragOperationType (*wantedDropOperation)(WMView *self);
    WMArray* (*askedOperations)(WMView *self);
    Bool (*acceptDropOperation)(WMView *self, WMDragOperationType operation);
    void (*beganDrag)(WMView *self, WMPoint *point);
    void (*endedDrag)(WMView *self, WMPoint *point, Bool deposited);
    WMData* (*fetchDragData)(WMView *self, char *type);
    /*Bool (*ignoreModifierKeysWhileDragging)(WMView *view);*/
} WMDragSourceProcs;



typedef struct W_DragDestinationProcs {
    void (*prepareForDragOperation)(WMView *self);
    WMArray* (*requiredDataTypes)(WMView *self, WMDragOperationType request,
                                  WMArray *sourceDataTypes);
    WMDragOperationType (*allowedOperation)(WMView *self,
                                            WMDragOperationType request,
                                            WMArray *sourceDataTypes);
    Bool (*inspectDropData)(WMView *self, WMArray *dropData);
    void (*performDragOperation)(WMView *self, WMArray *dropData,
                                 WMArray *operations, WMPoint *dropLocation);
    void (*concludeDragOperation)(WMView *self);
} WMDragDestinationProcs;


/* ...................................................................... */


WMPoint wmkpoint(int x, int y);

WMSize wmksize(unsigned int width, unsigned int height);

WMRect wmkrect(int x, int y, unsigned int width, unsigned int height);

#ifdef ANSI_C_DOESNT_LIKE_IT_THIS_WAY
#define wmksize(width, height) (WMSize){(width), (height)}
#define wmkpoint(x, y)         (WMPoint){(x), (y)}
#endif

/* ....................................................................... */



void WMInitializeApplication(char *applicationName, int *argc, char **argv);

void WMSetResourcePath(char *path);

/* Try to locate resource file. ext may be NULL */
char* WMPathForResourceOfType(char *resource, char *ext);


WMScreen* WMOpenScreen(const char *display);

WMScreen* WMCreateScreenWithRContext(Display *display, int screen,
                                     RContext *context);

WMScreen* WMCreateScreen(Display *display, int screen);

WMScreen* WMCreateSimpleApplicationScreen(Display *display);

void WMScreenMainLoop(WMScreen *scr);

void WMBreakModalLoop(WMScreen *scr);

void WMRunModalLoop(WMScreen *scr, WMView *view);

RContext* WMScreenRContext(WMScreen *scr);

Display* WMScreenDisplay(WMScreen *scr);

int WMScreenDepth(WMScreen *scr);



void WMSetApplicationIconImage(WMScreen *app, RImage *image);

RImage* WMGetApplicationIconImage(WMScreen *app);

void WMSetApplicationIconPixmap(WMScreen *app, WMPixmap *icon);

WMPixmap* WMGetApplicationIconPixmap(WMScreen *app);

/* If color==NULL it will use the default color for panels: ae/aa/ae */
WMPixmap* WMCreateApplicationIconBlendedPixmap(WMScreen *scr, RColor *color);

void WMSetApplicationIconWindow(WMScreen *scr, Window window);

void WMSetFocusToWidget(WMWidget *widget);

WMEventHook* WMHookEventHandler(WMEventHook *handler);

int WMHandleEvent(XEvent *event);

Bool WMScreenPending(WMScreen *scr);

void WMCreateEventHandler(WMView *view, unsigned long mask,
                          WMEventProc *eventProc, void *clientData);

void WMDeleteEventHandler(WMView *view, unsigned long mask,
                          WMEventProc *eventProc, void *clientData);

int WMIsDoubleClick(XEvent *event);

/*int WMIsTripleClick(XEvent *event);*/

void WMNextEvent(Display *dpy, XEvent *event);

void WMMaskEvent(Display *dpy, long mask, XEvent *event);


/* ....................................................................... */


Bool WMCreateSelectionHandler(WMView *view, Atom selection, Time timestamp,
                              WMSelectionProcs *procs, void *cdata);

void WMDeleteSelectionHandler(WMView *view, Atom selection, Time timestamp);

Bool WMRequestSelection(WMView *view, Atom selection, Atom target,
                        Time timestamp, WMSelectionCallback *callback,
                        void *cdata);


extern char *WMSelectionOwnerDidChangeNotification;

/* ....................................................................... */

WMArray* WMCreateDragOperationArray(int initialSize);

WMDragOperationItem* WMCreateDragOperationItem(WMDragOperationType type,
                                               char* text);

WMDragOperationType WMGetDragOperationItemType(WMDragOperationItem* item);

char* WMGetDragOperationItemText(WMDragOperationItem* item);

void WMSetViewDragImage(WMView* view, WMPixmap *dragImage);

void WMReleaseViewDragImage(WMView* view);

void WMSetViewDragSourceProcs(WMView *view, WMDragSourceProcs *procs);

Bool WMIsDraggingFromView(WMView *view);

void WMDragImageFromView(WMView *view, XEvent *event);

/* Create a drag handler, associating drag event masks with dragEventProc */
void WMCreateDragHandler(WMView *view, WMEventProc *dragEventProc, void *clientData);

void WMDeleteDragHandler(WMView *view, WMEventProc *dragEventProc, void *clientData);

/* set default drag handler for view */
void WMSetViewDraggable(WMView *view, WMDragSourceProcs *procs, WMPixmap *dragImage);

void WMUnsetViewDraggable(WMView *view);

void WMRegisterViewForDraggedTypes(WMView *view, WMArray *acceptedTypes);

void WMUnregisterViewDraggedTypes(WMView *view);

void WMSetViewDragDestinationProcs(WMView *view, WMDragDestinationProcs *procs);

/* ....................................................................... */

Bool WMIsAntialiasingEnabled(WMScreen *scrPtr);

/* ....................................................................... */

WMFont* WMCreateFont(WMScreen *scrPtr, char *fontName);

WMFont* WMCopyFontWithStyle(WMScreen *scrPtr, WMFont *font, WMFontStyle style);

WMFont* WMRetainFont(WMFont *font);

void WMReleaseFont(WMFont *font);

char* WMGetFontName(WMFont *font);

unsigned int WMFontHeight(WMFont *font);

void WMSetWidgetDefaultFont(WMScreen *scr, WMFont *font);

void WMSetWidgetDefaultBoldFont(WMScreen *scr, WMFont *font);

WMFont* WMDefaultSystemFont(WMScreen *scrPtr);

WMFont* WMDefaultBoldSystemFont(WMScreen *scrPtr);

WMFont* WMSystemFontOfSize(WMScreen *scrPtr, int size);

WMFont* WMBoldSystemFontOfSize(WMScreen *scrPtr, int size);

/* ....................................................................... */

WMPixmap* WMRetainPixmap(WMPixmap *pixmap);

void WMReleasePixmap(WMPixmap *pixmap);

WMPixmap* WMCreatePixmap(WMScreen *scrPtr, int width, int height, int depth,
                         Bool masked);

WMPixmap* WMCreatePixmapFromXPixmaps(WMScreen *scrPtr, Pixmap pixmap,
                                     Pixmap mask, int width, int height,
                                     int depth);

WMPixmap* WMCreatePixmapFromRImage(WMScreen *scrPtr, RImage *image,
                                   int threshold);

WMPixmap* WMCreatePixmapFromXPMData(WMScreen *scrPtr, char **data);

WMSize WMGetPixmapSize(WMPixmap *pixmap);

WMPixmap* WMCreatePixmapFromFile(WMScreen *scrPtr, char *fileName);

WMPixmap* WMCreateBlendedPixmapFromRImage(WMScreen *scrPtr, RImage *image,
                                          RColor *color);

WMPixmap* WMCreateBlendedPixmapFromFile(WMScreen *scrPtr, char *fileName,
                                        RColor *color);

void WMDrawPixmap(WMPixmap *pixmap, Drawable d, int x, int y);

Pixmap WMGetPixmapXID(WMPixmap *pixmap);

Pixmap WMGetPixmapMaskXID(WMPixmap *pixmap);

WMPixmap* WMGetSystemPixmap(WMScreen *scr, int image);

/* ....................................................................... */


WMColor* WMDarkGrayColor(WMScreen *scr);

WMColor* WMGrayColor(WMScreen *scr);

WMColor* WMBlackColor(WMScreen *scr);

WMColor* WMWhiteColor(WMScreen *scr);

void WMSetColorInGC(WMColor *color, GC gc);

GC WMColorGC(WMColor *color);

WMPixel WMColorPixel(WMColor *color);

void WMPaintColorSwatch(WMColor *color, Drawable d, int x, int y,
                        unsigned int width, unsigned int height);

void WMReleaseColor(WMColor *color);

WMColor* WMRetainColor(WMColor *color);

WMColor* WMCreateRGBColor(WMScreen *scr, unsigned short red,
                          unsigned short green, unsigned short blue,
                          Bool exact);

WMColor* WMCreateRGBAColor(WMScreen *scr, unsigned short red,
                           unsigned short green, unsigned short blue,
                           unsigned short alpha, Bool exact);

WMColor* WMCreateNamedColor(WMScreen *scr, char *name, Bool exact);

RColor WMGetRColorFromColor(WMColor *color);

void WMSetColorAlpha(WMColor *color, unsigned short alpha);

unsigned short WMRedComponentOfColor(WMColor *color);

unsigned short WMGreenComponentOfColor(WMColor *color);

unsigned short WMBlueComponentOfColor(WMColor *color);

unsigned short WMGetColorAlpha(WMColor *color);

char* WMGetColorRGBDescription(WMColor *color);

/* ....................................................................... */


void WMDrawString(WMScreen *scr, Drawable d, WMColor *color, WMFont *font,
                  int x, int y, char *text, int length);

void WMDrawImageString(WMScreen *scr, Drawable d, WMColor *color,
                       WMColor *background, WMFont *font, int x, int y,
                       char *text, int length);

int WMWidthOfString(WMFont *font, char *text, int length);



/* ....................................................................... */

WMScreen* WMWidgetScreen(WMWidget *w);

unsigned int WMScreenWidth(WMScreen *scr);

unsigned int WMScreenHeight(WMScreen *scr);

void WMUnmapWidget(WMWidget *w);

void WMMapWidget(WMWidget *w);

Bool WMWidgetIsMapped(WMWidget *w);

void WMRaiseWidget(WMWidget *w);

void WMLowerWidget(WMWidget *w);

void WMMoveWidget(WMWidget *w, int x, int y);

void WMResizeWidget(WMWidget *w, unsigned int width, unsigned int height);

void WMSetWidgetBackgroundColor(WMWidget *w, WMColor *color);

WMColor* WMGetWidgetBackgroundColor(WMWidget *w);

void WMMapSubwidgets(WMWidget *w);

void WMUnmapSubwidgets(WMWidget *w);

void WMRealizeWidget(WMWidget *w);

void WMReparentWidget(WMWidget *w, WMWidget *newParent, int x, int y);

void WMDestroyWidget(WMWidget *widget);

void WMHangData(WMWidget *widget, void *data);

void* WMGetHangedData(WMWidget *widget);

unsigned int WMWidgetWidth(WMWidget *w);

unsigned int WMWidgetHeight(WMWidget *w);

Window WMWidgetXID(WMWidget *w);

Window WMViewXID(WMView *view);

void WMRedisplayWidget(WMWidget *w);

void WMSetViewNotifySizeChanges(WMView *view, Bool flag);

void WMSetViewExpandsToParent(WMView *view, int topOffs, int leftOffs,
                              int rightOffs, int bottomOffs);

WMSize WMGetViewSize(WMView *view);

WMPoint WMGetViewPosition(WMView *view);

WMPoint WMGetViewScreenPosition(WMView *view);

WMWidget* WMWidgetOfView(WMView *view);

void WMSetViewNextResponder(WMView *view, WMView *responder);

void WMRelayToNextResponder(WMView *view, XEvent *event);

/* notifications */
extern char *WMViewSizeDidChangeNotification;

extern char *WMViewFocusDidChangeNotification;

extern char *WMViewRealizedNotification;


/* ....................................................................... */

void WMSetBalloonTextForView(char *text, WMView *view);

void WMSetBalloonTextAlignment(WMScreen *scr, WMAlignment alignment);

void WMSetBalloonFont(WMScreen *scr, WMFont *font);

void WMSetBalloonTextColor(WMScreen *scr, WMColor *color);

void WMSetBalloonDelay(WMScreen *scr, int delay);

void WMSetBalloonEnabled(WMScreen *scr, Bool flag);


/* ....................................................................... */

WMWindow* WMCreateWindow(WMScreen *screen, char *name);

WMWindow* WMCreateWindowWithStyle(WMScreen *screen, char *name, int style);

WMWindow* WMCreatePanelWithStyleForWindow(WMWindow *owner, char *name,
                                          int style);

WMWindow* WMCreatePanelForWindow(WMWindow *owner, char *name);

void WMChangePanelOwner(WMWindow *win, WMWindow *newOwner);

void WMSetWindowTitle(WMWindow *wPtr, char *title);

void WMSetWindowMiniwindowTitle(WMWindow *win, char *title);

void WMSetWindowMiniwindowImage(WMWindow *win, RImage *image);

void WMSetWindowMiniwindowPixmap(WMWindow *win, WMPixmap *pixmap);

void WMSetWindowCloseAction(WMWindow *win, WMAction *action, void *clientData);

void WMSetWindowInitialPosition(WMWindow *win, int x, int y);

void WMSetWindowUserPosition(WMWindow *win, int x, int y);

void WMSetWindowAspectRatio(WMWindow *win, int minX, int minY,
                            int maxX, int maxY);

void WMSetWindowMaxSize(WMWindow *win, unsigned width, unsigned height);

void WMSetWindowMinSize(WMWindow *win, unsigned width, unsigned height);

void WMSetWindowBaseSize(WMWindow *win, unsigned width, unsigned height);

void WMSetWindowResizeIncrements(WMWindow *win, unsigned wIncr, unsigned hIncr);

void WMSetWindowLevel(WMWindow *win, int level);

void WMSetWindowDocumentEdited(WMWindow *win, Bool flag);

void WMCloseWindow(WMWindow *win);

/* ....................................................................... */

void WMSetButtonAction(WMButton *bPtr, WMAction *action, void *clientData);

#define WMCreateCommandButton(parent) \
    WMCreateCustomButton((parent), WBBSpringLoadedMask\
    |WBBPushInMask\
    |WBBPushLightMask\
    |WBBPushChangeMask)

#define WMCreateRadioButton(parent) \
    WMCreateButton((parent), WBTRadio)

#define WMCreateSwitchButton(parent) \
    WMCreateButton((parent), WBTSwitch)

WMButton* WMCreateButton(WMWidget *parent, WMButtonType type);

WMButton* WMCreateCustomButton(WMWidget *parent, int behaviourMask);

void WMSetButtonImageDefault(WMButton *bPtr);

void WMSetButtonImage(WMButton *bPtr, WMPixmap *image);

void WMSetButtonAltImage(WMButton *bPtr, WMPixmap *image);

void WMSetButtonImagePosition(WMButton *bPtr, WMImagePosition position);

void WMSetButtonFont(WMButton *bPtr, WMFont *font);

void WMSetButtonTextAlignment(WMButton *bPtr, WMAlignment alignment);

void WMSetButtonText(WMButton *bPtr, char *text);

void WMSetButtonAltText(WMButton *bPtr, char *text);

void WMSetButtonTextColor(WMButton *bPtr, WMColor *color);

void WMSetButtonAltTextColor(WMButton *bPtr, WMColor *color);

void WMSetButtonDisabledTextColor(WMButton *bPtr, WMColor *color);

void WMSetButtonSelected(WMButton *bPtr, int isSelected);

int WMGetButtonSelected(WMButton *bPtr);

void WMSetButtonBordered(WMButton *bPtr, int isBordered);

void WMSetButtonEnabled(WMButton *bPtr, Bool flag);

int WMGetButtonEnabled(WMButton *bPtr);

void WMSetButtonImageDimsWhenDisabled(WMButton *bPtr, Bool flag);

void WMSetButtonTag(WMButton *bPtr, int tag);

void WMGroupButtons(WMButton *bPtr, WMButton *newMember);

void WMPerformButtonClick(WMButton *bPtr);

void WMSetButtonContinuous(WMButton *bPtr, Bool flag);

void WMSetButtonPeriodicDelay(WMButton *bPtr, float delay, float interval);

/* ....................................................................... */

WMLabel* WMCreateLabel(WMWidget *parent);

void WMSetLabelWraps(WMLabel *lPtr, Bool flag);

void WMSetLabelImage(WMLabel *lPtr, WMPixmap *image);

WMPixmap* WMGetLabelImage(WMLabel *lPtr);

char* WMGetLabelText(WMLabel *lPtr);

void WMSetLabelImagePosition(WMLabel *lPtr, WMImagePosition position);

void WMSetLabelTextAlignment(WMLabel *lPtr, WMAlignment alignment);

void WMSetLabelRelief(WMLabel *lPtr, WMReliefType relief);

void WMSetLabelText(WMLabel *lPtr, char *text);

WMFont* WMGetLabelFont(WMLabel *lPtr);

void WMSetLabelFont(WMLabel *lPtr, WMFont *font);

void WMSetLabelTextColor(WMLabel *lPtr, WMColor *color);

/* ....................................................................... */

WMFrame* WMCreateFrame(WMWidget *parent);

void WMSetFrameTitlePosition(WMFrame *fPtr, WMTitlePosition position);

void WMSetFrameRelief(WMFrame *fPtr, WMReliefType relief);

void WMSetFrameTitle(WMFrame *fPtr, char *title);

/* ....................................................................... */

Bool WMMenuItemIsSeparator(WMMenuItem *item);

WMMenuItem* WMCreateMenuItem(void);

void WMDestroyMenuItem(WMMenuItem *item);

Bool WMGetMenuItemEnabled(WMMenuItem *item);

void WMSetMenuItemEnabled(WMMenuItem *item, Bool flag);

char* WMGetMenuItemShortcut(WMMenuItem *item);

unsigned WMGetMenuItemShortcutModifierMask(WMMenuItem *item);

void WMSetMenuItemShortcut(WMMenuItem *item, char *shortcut);

void WMSetMenuItemShortcutModifierMask(WMMenuItem *item, unsigned mask);

void* WMGetMenuItemRepresentedObject(WMMenuItem *item);

void WMSetMenuItemRepresentedObject(WMMenuItem *item, void *object);

void WMSetMenuItemAction(WMMenuItem *item, WMAction *action, void *data);

WMAction* WMGetMenuItemAction(WMMenuItem *item);

void* WMGetMenuItemData(WMMenuItem *item);

void WMSetMenuItemTitle(WMMenuItem *item, char *title);

char* WMGetMenuItemTitle(WMMenuItem *item);

void WMSetMenuItemState(WMMenuItem *item, int state);

int WMGetMenuItemState(WMMenuItem *item);

void WMSetMenuItemPixmap(WMMenuItem *item, WMPixmap *pixmap);

WMPixmap* WMGetMenuItemPixmap(WMMenuItem *item);

void WMSetMenuItemOnStatePixmap(WMMenuItem *item, WMPixmap *pixmap);

WMPixmap* WMGetMenuItemOnStatePixmap(WMMenuItem *item);

void WMSetMenuItemOffStatePixmap(WMMenuItem *item, WMPixmap *pixmap);

WMPixmap* WMGetMenuItemOffStatePixmap(WMMenuItem *item);

void WMSetMenuItemMixedStatePixmap(WMMenuItem *item, WMPixmap *pixmap);

WMPixmap* WMGetMenuItemMixedStatePixmap(WMMenuItem *item);

/*void WMSetMenuItemSubmenu(WMMenuItem *item, WMMenu *submenu);


WMMenu* WMGetMenuItemSubmenu(WMMenuItem *item);

Bool WMGetMenuItemHasSubmenu(WMMenuItem *item);
*/

/* ....................................................................... */

WMPopUpButton* WMCreatePopUpButton(WMWidget *parent);

void WMSetPopUpButtonAction(WMPopUpButton *sPtr, WMAction *action,
                            void *clientData);

void WMSetPopUpButtonPullsDown(WMPopUpButton *bPtr, Bool flag);

WMMenuItem* WMAddPopUpButtonItem(WMPopUpButton *bPtr, char *title);

WMMenuItem* WMInsertPopUpButtonItem(WMPopUpButton *bPtr, int index,
                                    char *title);

void WMRemovePopUpButtonItem(WMPopUpButton *bPtr, int index);

void WMSetPopUpButtonItemEnabled(WMPopUpButton *bPtr, int index, Bool flag);

Bool WMGetPopUpButtonItemEnabled(WMPopUpButton *bPtr, int index);

void WMSetPopUpButtonSelectedItem(WMPopUpButton *bPtr, int index);

int WMGetPopUpButtonSelectedItem(WMPopUpButton *bPtr);

void WMSetPopUpButtonText(WMPopUpButton *bPtr, char *text);

/* don't free the returned data */
char* WMGetPopUpButtonItem(WMPopUpButton *bPtr, int index);

WMMenuItem* WMGetPopUpButtonMenuItem(WMPopUpButton *bPtr, int index);

int WMGetPopUpButtonNumberOfItems(WMPopUpButton *bPtr);

void WMSetPopUpButtonEnabled(WMPopUpButton *bPtr, Bool flag);

Bool WMGetPopUpButtonEnabled(WMPopUpButton *bPtr);

/* ....................................................................... */

WMBox* WMCreateBox(WMWidget *parent);

void WMSetBoxBorderWidth(WMBox *box, unsigned width);

void WMAddBoxSubview(WMBox *bPtr, WMView *view, Bool expand, Bool fill,
                     int minSize, int maxSize, int space);

void WMAddBoxSubviewAtEnd(WMBox *bPtr, WMView *view, Bool expand, Bool fill,
                          int minSize, int maxSize, int space);

void WMRemoveBoxSubview(WMBox *bPtr, WMView *view);

void WMSetBoxHorizontal(WMBox *box, Bool flag);

/* ....................................................................... */

int WMRunAlertPanel(WMScreen *app, WMWindow *owner, char *title, char *msg,
                    char *defaultButton, char *alternateButton,
                    char *otherButton);

WMAlertPanel* WMCreateAlertPanel(WMScreen *app, WMWindow *owner, char *title,
                                 char *msg, char *defaultButton,
                                 char *alternateButton, char *otherButton);
void WMDestroyAlertPanel(WMAlertPanel *panel);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif

