#ifndef _WINGSP_H_
#define _WINGSP_H_


#include <X11/Xlib.h>
#include <X11/Xutil.h>


#include <WINGs/WINGs.h>

#if WINGS_H_VERSION < 20041030
#error There_is_an_old_WINGs.h_file_somewhere_in_your_system._Please_remove_it.
#endif

#include <assert.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */


#define DOUBLE_BUFFER   1

#define WC_UserWidget	128

#define SCROLLER_WIDTH	20

#define XDND_VERSION    4


typedef struct W_Application {
    char *applicationName;
    int argc;
    char **argv;
} W_Application;


typedef struct W_Font {
    struct W_Screen *screen;

    struct _XftFont *font;

    short height;
    short y;
    short refCount;
    char *name;
} W_Font;


typedef struct W_Pixmap {
    struct W_Screen *screen;
    Pixmap pixmap;
    Pixmap mask;
    unsigned short width;
    unsigned short height;
    short depth;
    short refCount;
} W_Pixmap;


typedef struct W_Color {
    struct W_Screen *screen;

    XColor color;
    unsigned short alpha;
    short refCount;
    GC gc;
    struct {
        unsigned int exact:1;
    } flags;
} W_Color;


typedef struct W_FocusInfo {
    struct W_View *toplevel;
    struct W_View *focused;	       /* view that has the focus in this toplevel */
    struct W_FocusInfo *next;
} W_FocusInfo;



typedef void* W_DndState(WMView *destView, XClientMessageEvent *event,
                         WMDraggingInfo *info);


typedef struct W_DragOperationItem {
    WMDragOperationType type;
    char* text;
} W_DragOperationItem;


typedef struct W_DragSourceInfo {
    WMView *sourceView;
    Window destinationWindow;
    W_DndState *state;
    WMSelectionProcs *selectionProcs;
    Window icon;
    WMPoint imageLocation;
    WMPoint mouseOffset; /* mouse pos in icon */
    Cursor dragCursor;
    WMRect noPositionMessageZone;
    Atom firstThreeTypes[3];
} W_DragSourceInfo;


typedef struct W_DragDestinationInfo {
    WMView *destView;
    Window sourceWindow;
    W_DndState *state;
    WMArray *sourceTypes;
    WMArray *requiredTypes;
    Bool typeListAvailable;
    WMArray *dropDatas;
} W_DragDestinationInfo;


struct W_DraggingInfo {
    unsigned char protocolVersion;
    Time timestamp;

    Atom sourceAction;
    Atom destinationAction;

    W_DragSourceInfo* sourceInfo;    /* infos needed by source */
    W_DragDestinationInfo* destInfo; /* infos needed by destination */
} W_DraggingInfo;


typedef struct W_Screen {
    Display *display;
    int screen;
    int depth;

    Colormap colormap;

    Visual *visual;

    Time lastEventTime;

    Window rootWin;

    struct W_View *rootView;

    RContext *rcontext;

    struct W_IMContext *imctx;

    struct _XftDraw *xftdraw;          /* shared XftDraw */

    /* application related */

    W_FocusInfo *focusInfo;

    RImage *applicationIconImage;      /* image (can have alpha channel) */
    struct W_Pixmap *applicationIconPixmap; /* pixmap - no alpha channel */
    Window applicationIconWindow;

    struct W_Window *windowList;       /* list of windows in the app */

    Window groupLeader;		       /* the leader of the application */
                                       /* also used for other things */

    struct W_SelectionHandlers *selectionHandlerList;

    struct {
        unsigned int hasAppIcon:1;
        unsigned int simpleApplication:1;
    } aflags;

    Pixmap stipple;

    struct W_View *dragSourceView;
    struct W_DraggingInfo dragInfo;

    /* colors */
    W_Color *white;
    W_Color *black;
    W_Color *gray;
    W_Color *darkGray;

    GC stippleGC;

    GC copyGC;
    GC clipGC;

    GC monoGC;			       /* GC for 1bpp visuals */

    GC xorGC;

    GC ixorGC;			       /* IncludeInferiors XOR */

    GC drawStringGC;                   /* for WMDrawString() */

    GC drawImStringGC;                 /* for WMDrawImageString() */

    W_Font *normalFont;

    W_Font *boldFont;

    WMHashTable *fontCache;

    Bool antialiasedText;

    unsigned int ignoredModifierMask; /* modifiers to ignore when typing txt */

    struct W_Balloon *balloon;


    struct W_Pixmap *checkButtonImageOn;
    struct W_Pixmap *checkButtonImageOff;

    struct W_Pixmap *radioButtonImageOn;
    struct W_Pixmap *radioButtonImageOff;

    struct W_Pixmap *buttonArrow;
    struct W_Pixmap *pushedButtonArrow;

    struct W_Pixmap *scrollerDimple;

    struct W_Pixmap *upArrow;
    struct W_Pixmap *downArrow;
    struct W_Pixmap *leftArrow;
    struct W_Pixmap *rightArrow;

    struct W_Pixmap *hiUpArrow;
    struct W_Pixmap *hiDownArrow;
    struct W_Pixmap *hiLeftArrow;
    struct W_Pixmap *hiRightArrow;

    struct W_Pixmap *pullDownIndicator;
    struct W_Pixmap *popUpIndicator;

    struct W_Pixmap *checkMark;

    struct W_Pixmap *homeIcon;
    struct W_Pixmap *altHomeIcon;

    struct W_Pixmap *trashcanIcon;
    struct W_Pixmap *altTrashcanIcon;

    struct W_Pixmap *createDirIcon;
    struct W_Pixmap *altCreateDirIcon;

    struct W_Pixmap *disketteIcon;
    struct W_Pixmap *altDisketteIcon;
    struct W_Pixmap *unmountIcon;
    struct W_Pixmap *altUnmountIcon;

    struct W_Pixmap *magnifyIcon;
    /*struct W_Pixmap *altMagnifyIcon;*/
    struct W_Pixmap *wheelIcon;
    struct W_Pixmap *grayIcon;
    struct W_Pixmap *rgbIcon;
    struct W_Pixmap *cmykIcon;
    struct W_Pixmap *hsbIcon;
    struct W_Pixmap *customPaletteIcon;
    struct W_Pixmap *colorListIcon;

    struct W_Pixmap *defaultObjectIcon;

    Cursor defaultCursor;

    Cursor textCursor;

    Cursor invisibleCursor;

    Atom attribsAtom;		       /* GNUstepWindowAttributes */

    Atom deleteWindowAtom;	       /* WM_DELETE_WINDOW */

    Atom protocolsAtom;		       /* _XA_WM_PROTOCOLS */

    Atom clipboardAtom;		       /* CLIPBOARD */

    Atom xdndAwareAtom;		       /* XdndAware */
    Atom xdndSelectionAtom;
    Atom xdndEnterAtom;
    Atom xdndLeaveAtom;
    Atom xdndPositionAtom;
    Atom xdndDropAtom;
    Atom xdndFinishedAtom;
    Atom xdndTypeListAtom;
    Atom xdndActionListAtom;
    Atom xdndActionDescriptionAtom;
    Atom xdndStatusAtom;

    Atom xdndActionCopy;
    Atom xdndActionMove;
    Atom xdndActionLink;
    Atom xdndActionAsk;
    Atom xdndActionPrivate;

    Atom wmIconDragOffsetAtom;

    Atom wmStateAtom;		       /* WM_STATE */
    
    Atom utf8String;

    Atom netwmName;
    Atom netwmIconName;
    Atom netwmIcon;

    /* stuff for detecting double-clicks */
    Time lastClickTime;		       /* time of last mousedown event */
    Window lastClickWindow;	       /* window of the last mousedown */

    struct W_View *modalView;
    unsigned modalLoop:1;
    unsigned ignoreNextDoubleClick:1;
} W_Screen;



typedef struct W_ViewDelegate {
    void *data;

    void (*didMove)(struct W_ViewDelegate*, WMView*);

    void (*didResize)(struct W_ViewDelegate*, WMView*);

    void (*willMove)(struct W_ViewDelegate*, WMView*, int*, int*);

    void (*willResize)(struct W_ViewDelegate*, WMView*,
                       unsigned int*, unsigned int*);
} W_ViewDelegate;



typedef struct W_View {
    struct W_Screen *screen;

    WMWidget *self;		       /* must point to the widget the
    * view belongs to */

    W_ViewDelegate *delegate;

    Window window;

    WMSize size;

    short topOffs;
    short leftOffs;
    short bottomOffs;
    short rightOffs;

    WMPoint pos;

    struct W_View *nextFocusChain;     /* next/prev in focus chain */
    struct W_View *prevFocusChain;

    struct W_View *nextResponder;      /* next to receive keyboard events */

    struct W_View *parent;	       /* parent WMView */

    struct W_View *childrenList;       /* first in list of child windows */

    struct W_View *nextSister;	       /* next on parent's children list */

    WMArray *eventHandlers;	       /* event handlers for this window */

    unsigned long attribFlags;
    XSetWindowAttributes attribs;

    void *hangedData;		       /* data holder for user program */

    WMColor *backColor;

    Cursor cursor;

    Atom *droppableTypes;
    struct W_DragSourceProcs      *dragSourceProcs;
    struct W_DragDestinationProcs *dragDestinationProcs;
    WMPixmap *dragImage;
    int helpContext;

    XIC xic;

    struct {
        unsigned int realized:1;
        unsigned int mapped:1;
        unsigned int parentDying:1;
        unsigned int dying:1;	        /* the view is being destroyed */
        unsigned int topLevel:1;        /* is a top level window */
        unsigned int root:1;	        /* is the root window */
        unsigned int mapWhenRealized:1; /* map the view when it's realized */
        unsigned int alreadyDead:1;     /* view was freed */

        unsigned int dontCompressMotion:1; /* motion notify event compress */
        unsigned int notifySizeChanged:1;
        unsigned int dontCompressExpose:1; /* expose event compress */

        /* toplevel only */
        unsigned int worksWhenModal:1;
        unsigned int pendingRelease1:1;
        unsigned int pendingRelease2:1;
        unsigned int pendingRelease3:1;
        unsigned int pendingRelease4:1;
        unsigned int pendingRelease5:1;
        unsigned int xdndHintSet:1;
    } flags;

    int refCount;
} W_View;


typedef struct W_EventHandler {
    unsigned long eventMask;

    WMEventProc *proc;

    void *clientData;
} W_EventHandler;

#define CHECK_CLASS(widget, class) assert(W_CLASS(widget)==(class))


#define W_CLASS(widget)  	(((W_WidgetType*)(widget))->widgetClass)
#define W_VIEW(widget)   	(((W_WidgetType*)(widget))->view)

#define W_VIEW_REALIZED(view)	(view)->flags.realized
#define W_VIEW_MAPPED(view)	(view)->flags.mapped

#define W_VIEW_DISPLAY(view)    (view)->screen->display
#define W_VIEW_SCREEN(view)	(view)->screen
#define W_VIEW_DRAWABLE(view)	(view)->window

#define W_VIEW_WIDTH(view)	(view)->size.width
#define W_VIEW_HEIGHT(view)	(view)->size.height


#define W_PIXEL(c)		(c)->color.pixel

#define W_FONTID(f)		(f)->font->fid

#define W_DRAWABLE(scr)		(scr)->rcontext->drawable



W_View *W_GetViewForXWindow(Display *display, Window window);

W_View *W_CreateView(W_View *parent);

W_View *W_CreateTopView(W_Screen *screen);

W_View *W_CreateUnmanagedTopView(W_Screen *screen);


W_View *W_CreateRootView(W_Screen *screen);

void W_DestroyView(W_View *view);

void W_RealizeView(W_View *view);

void W_ReparentView(W_View *view, W_View *newParent, int x, int y);

void W_RaiseView(W_View *view);

void W_LowerView(W_View *view);


void W_MapView(W_View *view);

void W_MapSubviews(W_View *view);

void W_UnmapSubviews(W_View *view);

W_View *W_TopLevelOfView(W_View *view);

void W_UnmapView(W_View *view);

void W_MoveView(W_View *view, int x, int y);

void W_ResizeView(W_View *view, unsigned int width, unsigned int height);

void W_SetViewBackgroundColor(W_View *view, WMColor *color);

void W_SetViewCursor(W_View *view, Cursor cursor);

void W_DrawRelief(W_Screen *scr, Drawable d, int x, int y, unsigned int width,
                  unsigned int height, WMReliefType relief);

void W_DrawReliefWithGC(W_Screen *scr, Drawable d, int x, int y,
                        unsigned int width, unsigned int height,
                        WMReliefType relief,
                        GC black, GC dark, GC light, GC white);

void W_CallDestroyHandlers(W_View *view);

void W_PaintTextAndImage(W_View *view, int wrap, WMColor *textColor,
                         W_Font *font, WMReliefType relief, char *text,
                         WMAlignment alignment, W_Pixmap *image,
                         WMImagePosition position, WMColor *backColor, int ofs);

void W_PaintText(W_View *view, Drawable d, WMFont *font,  int x, int y,
                 int width, WMAlignment alignment, WMColor *color,
                 int wrap, char *text, int length);

int W_GetTextHeight(WMFont *font, char *text, int width, int wrap);


int W_TextWidth(WMFont *font, char *text, int length);


void W_BroadcastMessage(W_View *targetParent, XEvent *event);

void W_DispatchMessage(W_View *target, XEvent *event);

void W_SetFocusOfToplevel(W_View *toplevel, W_View *view);

W_View *W_FocusedViewOfToplevel(W_View *view);

void W_SetFocusOfTopLevel(W_View *toplevel, W_View *view);

void W_ReleaseView(WMView *view);

WMView *W_RetainView(WMView *view);

void W_InitApplication(WMScreen *scr);

void W_InitNotificationCenter(void);

W_Class W_RegisterUserWidget(void);

void W_RedisplayView(WMView *view);

Bool W_ApplicationInitialized(void);

void W_HandleSelectionEvent(XEvent *event);

void W_HandleDNDClientMessage(WMView *toplevel, XClientMessageEvent *event);

void W_FlushASAPNotificationQueue(void);

void W_FlushIdleNotificationQueue(void);

struct W_Balloon *W_CreateBalloon(WMScreen *scr);

void W_BalloonHandleEnterView(WMView *view);

void W_BalloonHandleLeaveView(WMView *view);

Bool W_CheckIdleHandlers(void);

void W_CheckTimerHandlers(void);

Bool W_HandleInputEvents(Bool waitForInput, int inputfd);

/* XDnD */
Atom W_OperationToAction(WMScreen *scr, WMDragOperationType operation);

WMDragOperationType W_ActionToOperation(WMScreen *scr, Atom action);

void W_FreeDragOperationItem(void* item);

Bool W_SendDnDClientMessage(Display *dpy, Window win, Atom message,
                            unsigned long data1, unsigned long data2,
                            unsigned long data3, unsigned long data4,
                            unsigned long data5);

void W_DragSourceStartTimer(WMDraggingInfo *info);

void W_DragSourceStopTimer();

void W_DragSourceStateHandler(WMDraggingInfo *info, XClientMessageEvent *event);

void W_DragDestinationStartTimer(WMDraggingInfo *info);

void W_DragDestinationStopTimer();

void W_DragDestinationStoreEnterMsgInfo(WMDraggingInfo *info, WMView *toplevel,
                                        XClientMessageEvent *event);

void W_DragDestinationStorePositionMsgInfo(WMDraggingInfo *info,
                                           WMView *toplevel,
                                           XClientMessageEvent *event);

void W_DragDestinationCancelDropOnEnter(WMView *toplevel, WMDraggingInfo *info);

void W_DragDestinationStateHandler(WMDraggingInfo *info,
                                   XClientMessageEvent *event);

void W_DragDestinationInfoClear(WMDraggingInfo *info);

void W_FreeViewXdndPart(WMView *view);

/* XIM */
void W_InitIM(WMScreen *scr);

void W_CreateIC(WMView *view);

void W_DestroyIC(WMView *view);

void W_FocusIC(WMView *view);

void W_UnFocusIC(WMView *view);

void W_SetPreeditPositon(W_View *view, int x, int y);

int W_LookupString(W_View *view, XKeyPressedEvent *event, char *buffer,
                   int buflen, KeySym *keysym, Status *status);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* _WINGSP_H_ */

