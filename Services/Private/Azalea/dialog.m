/* dialog.c - dialog windows for internal use
 *
 *  Window Maker window manager
 *
 *  Copyright (c) 1997-2003 Alfredo K. Kojima
 *  Copyright (c) 1998-2003 Dan Pascu
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
 *  USA.
 */

#include "wconfig.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <limits.h>

#include "WMDialogController.h"
#include "WMDefaults.h"

#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif

#include <signal.h>
#ifdef __FreeBSD__
#include <sys/signal.h>
#endif


#ifndef PATH_MAX
#define PATH_MAX DEFAULT_PATH_MAX
#endif

#include "WindowMaker.h"
#include "GNUstep.h"
#include "screen.h"
#include "dialog.h"
#include "funcs.h"
#include "stacking.h"
#include "framewin.h"
#include "window.h"
#include "actions.h"
#include "defaults.h"
#include "xinerama.h"



extern WPreferences wPreferences;


static WMPoint
getCenter(WScreen *scr, int width, int height)
{
    return wGetPointToCenterRectInHead(scr, wGetHeadForPointerLocation(scr),
                                       width, height);
}


int
wMessageDialog(WScreen *scr, char *title, char *message,
               char *defBtn, char *altBtn, char *othBtn)
{
#if 0
  /* Cannot do this because it might be called before NSApp start */
  WMDialogController *controller = [WMDialogController sharedController];
  NSString *tle, *msg;
  NSString *defaultButton, *alternateButton, *otherButton;

  if (title)
    tle = [NSString stringWithCString: title];
  else
    tle = nil;

  if (message)
    msg = [NSString stringWithCString: message];
  else
    msg = nil;

  if (defBtn)
    defaultButton = [NSString stringWithCString: defBtn];
  else
    defaultButton = nil;

  if (altBtn)
    alternateButton = [NSString stringWithCString: altBtn];
  else
    alternateButton = nil;

  if (othBtn)
    otherButton = [NSString stringWithCString: othBtn];
  else
    otherButton = nil;

  return [controller messageDialogWithTitle: tle
	                     message: msg
	 	       defaultButton: defaultButton
		     alternateButton: alternateButton
		         otherButton: otherButton];
#else
    WMAlertPanel *panel;
    Window parent;
    WWindow *wwin;
    int result;
    WMPoint center;

    panel = WMCreateAlertPanel(scr->wmscreen, NULL, title, message,
                               defBtn, altBtn, othBtn);

    parent = XCreateSimpleWindow(dpy, scr->root_win, 0, 0, 400, 180, 0, 0, 0);

    XReparentWindow(dpy, WMWidgetXID(panel->win), parent, 0, 0);


    center = getCenter(scr, 400, 180);
    wwin = wManageInternalWindow(scr, parent, None, NULL, center.x, center.y,
                                 400, 180);
    wwin->client_leader = WMWidgetXID(panel->win);

    WMMapWidget(panel->win);

    wWindowMap(wwin);

    WMRunModalLoop(WMWidgetScreen(panel->win), WMWidgetView(panel->win));

    result = panel->result;

    WMUnmapWidget(panel->win);

    wUnmanageWindow(wwin, False, False);

    WMDestroyAlertPanel(panel);

    XDestroyWindow(dpy, parent);

    return result;
#endif
}

int
wInputDialog(WScreen *scr, char *title, char *message, char **text)
{
#if 1
  NSString *tle, *msg, *txt;
  if (title)
    tle = [NSString stringWithCString: title];
  else
    tle = nil;

  if (message)
    msg = [NSString stringWithCString: message];
  else
    msg = nil;

  if (*text)
    txt = [NSString stringWithCString: *text];
  else
    txt = nil;

  WMDialogController *controller = [WMDialogController sharedController];
  NSString *string = [controller inputDialogWithTitle: tle
	                                      message: msg text: txt];
  if (string)
  {
    if (*text)
      wfree(*text);
    *text = wstrdup((char*)[string cString]);

    return True;
  }
  else
#endif
  {
    return False;
  }
}


/*
 *****************************************************************
 * Icon Selection Panel
 *****************************************************************
 */

Bool
wIconChooserDialog(WScreen *scr, char **file, char *instance, char *class)
{
  NSString *path = [[WMDialogController sharedController] iconChooserDialogWithInstance: [NSString stringWithCString: instance] class: [NSString stringWithCString: class]];
  if (path)
  {
    *file = wstrdup((char*)[path cString]);
    return True;
  }
  else
  {
    *file = NULL;
    return False;
  }
}


/*
 ***********************************************************************
 * Crashing Dialog Panel
 ***********************************************************************
 */

typedef struct _CrashPanel {
    WMWindow *win;            /* main window */

    WMLabel *iconL;           /* application icon */
    WMLabel *nameL;           /* title of panel */

    WMFrame *sepF;            /* separator frame */

    WMLabel *noteL;           /* Title of note */
    WMLabel *note2L;          /* body of note with what happened */

    WMFrame *whatF;           /* "what to do next" frame */
    WMPopUpButton *whatP;     /* action selection popup button */

    WMButton *okB;            /* ok button */

    Bool done;                /* if finished with this dialog */
    int action;               /* what to do after */

    KeyCode retKey;

} CrashPanel;


static void
handleKeyPress(XEvent *event, void *clientData)
{
    CrashPanel *panel = (CrashPanel*)clientData;

    if (event->xkey.keycode == panel->retKey) {
        WMPerformButtonClick(panel->okB);
    }
}


static void
okButtonCallback(void *self, void *clientData)
{
    CrashPanel *panel = (CrashPanel*)clientData;

    panel->done = True;
}


static void
setCrashAction(void *self, void *clientData)
{
    WMPopUpButton *pop = (WMPopUpButton*)self;
    CrashPanel *panel = (CrashPanel*)clientData;

    panel->action = WMGetPopUpButtonSelectedItem(pop);
}


/* Make this read the logo from a compiled in pixmap -Dan */
static WMPixmap*
getWindowMakerIconImage(WMScreen *scr)
{
    NSString *name = @"Logo.WMPanel";
    WMPixmap *pix=NULL;
    char *path;
    id value;

    value = [[WMDefaults sharedDefaults] objectForKey: WAIcon window: name];
    NSLog(@"value %@", value);

    if (value) {
        path = FindImage(wPreferences.icon_path, (char*)[value cString]);
	NSLog(@"path %s", path);

        if (path) {
            RColor gray;

            gray.red = 0xae;  gray.green = 0xaa;
            gray.blue = 0xae; gray.alpha = 0;

            pix = WMCreateBlendedPixmapFromFile(scr, path, &gray);
            wfree(path);
        }
    }

    return pix;
}


#define PWIDTH	295
#define PHEIGHT	345


int
wShowCrashingDialogPanel(int whatSig)
{
    CrashPanel *panel;
    WMScreen *scr;
    WMFont *font;
    WMPixmap *logo;
    int screen_no, scr_width, scr_height;
    int action;
    char buf[256];

    panel = wmalloc(sizeof(CrashPanel));
    memset(panel, 0, sizeof(CrashPanel));

    screen_no = DefaultScreen(dpy);
    scr_width = WidthOfScreen(ScreenOfDisplay(dpy, screen_no));
    scr_height = HeightOfScreen(ScreenOfDisplay(dpy, screen_no));

    scr = WMCreateScreen(dpy, screen_no);
    if (!scr) {
        wsyserror(("cannot open connection for crashing dialog panel. Aborting."));
        return WMAbort;
    }

    panel->retKey = XKeysymToKeycode(dpy, XK_Return);

    panel->win = WMCreateWindow(scr, "crashingDialog");
    WMResizeWidget(panel->win, PWIDTH, PHEIGHT);
    WMMoveWidget(panel->win, (scr_width - PWIDTH)/2, (scr_height - PHEIGHT)/2);

    logo = getWindowMakerIconImage(scr);
    if (logo) {
        panel->iconL = WMCreateLabel(panel->win);
        WMResizeWidget(panel->iconL, 64, 64);
        WMMoveWidget(panel->iconL, 10, 10);
        WMSetLabelImagePosition(panel->iconL, WIPImageOnly);
        WMSetLabelImage(panel->iconL, logo);
    }

    panel->nameL = WMCreateLabel(panel->win);
    WMResizeWidget(panel->nameL, 200, 30);
    WMMoveWidget(panel->nameL, 80, 25);
    WMSetLabelTextAlignment(panel->nameL, WALeft);
    font = WMBoldSystemFontOfSize(scr, 24);
    WMSetLabelFont(panel->nameL, font);
    WMReleaseFont(font);
    WMSetLabelText(panel->nameL, ("Fatal error"));

    panel->sepF = WMCreateFrame(panel->win);
    WMResizeWidget(panel->sepF, PWIDTH+4, 2);
    WMMoveWidget(panel->sepF, -2, 80);

    panel->noteL = WMCreateLabel(panel->win);
    WMResizeWidget(panel->noteL, PWIDTH-20, 40);
    WMMoveWidget(panel->noteL, 10, 90);
    WMSetLabelTextAlignment(panel->noteL, WAJustified);
#ifdef SYS_SIGLIST_DECLARED
    snprintf(buf, sizeof(buf), ("Window Maker received signal %i\n(%s)."),
             whatSig, sys_siglist[whatSig]);
#else
    snprintf(buf, sizeof(buf), ("Window Maker received signal %i."), whatSig);
#endif
    WMSetLabelText(panel->noteL, buf);

    panel->note2L = WMCreateLabel(panel->win);
    WMResizeWidget(panel->note2L, PWIDTH-20, 100);
    WMMoveWidget(panel->note2L, 10, 130);
    WMSetLabelTextAlignment(panel->note2L, WALeft);
    WMSetLabelText(panel->note2L,
                   (" This fatal error occured probably due to a bug."
                     " Please fill the included BUGFORM and "
                     "report it to bugs@windowmaker.org."));
    WMSetLabelWraps(panel->note2L, True);


    panel->whatF = WMCreateFrame(panel->win);
    WMResizeWidget(panel->whatF, PWIDTH-20, 50);
    WMMoveWidget(panel->whatF, 10, 240);
    WMSetFrameTitle(panel->whatF, ("What do you want to do now?"));

    panel->whatP = WMCreatePopUpButton(panel->whatF);
    WMResizeWidget(panel->whatP, PWIDTH-20-70, 20);
    WMMoveWidget(panel->whatP, 35, 20);
    WMSetPopUpButtonPullsDown(panel->whatP, False);
    WMSetPopUpButtonText(panel->whatP, ("Select action"));
    WMAddPopUpButtonItem(panel->whatP, ("Abort and leave a core file"));
    WMAddPopUpButtonItem(panel->whatP, ("Restart Window Maker"));
    WMAddPopUpButtonItem(panel->whatP, ("Start alternate window manager"));
    WMSetPopUpButtonAction(panel->whatP, setCrashAction, panel);
    WMSetPopUpButtonSelectedItem(panel->whatP, WMRestart);
    panel->action = WMRestart;

    WMMapSubwidgets(panel->whatF);

    panel->okB = WMCreateCommandButton(panel->win);
    WMResizeWidget(panel->okB, 80, 26);
    WMMoveWidget(panel->okB, 205, 309);
    WMSetButtonText(panel->okB, ("OK"));
    WMSetButtonImage(panel->okB, WMGetSystemPixmap(scr, WSIReturnArrow));
    WMSetButtonAltImage(panel->okB, WMGetSystemPixmap(scr, WSIHighlightedReturnArrow));
    WMSetButtonImagePosition(panel->okB, WIPRight);
    WMSetButtonAction(panel->okB, okButtonCallback, panel);

    panel->done = 0;

    WMCreateEventHandler(WMWidgetView(panel->win), KeyPressMask,
                         handleKeyPress, panel);

    WMRealizeWidget(panel->win);
    WMMapSubwidgets(panel->win);

    WMMapWidget(panel->win);

    XSetInputFocus(dpy, WMWidgetXID(panel->win), RevertToParent, CurrentTime);

    while (!panel->done) {
        XEvent event;

        WMNextEvent(dpy, &event);
        WMHandleEvent(&event);
    }

    action = panel->action;

    WMUnmapWidget(panel->win);
    WMDestroyWidget(panel->win);
    wfree(panel);

    return action;
}



/*****************************************************************************
 *			About GNUstep Panel
 *****************************************************************************/

#if 0 /* might be useful in the future */
static void
drawGNUstepLogo(Display *dpy, Drawable d, int width, int height,
                unsigned long blackPixel, unsigned long whitePixel)
{
    GC gc;
    XGCValues gcv;
    XRectangle rects[3];

    gcv.foreground = blackPixel;
    gc = XCreateGC(dpy, d, GCForeground, &gcv);

    XFillArc(dpy, d, gc, width/45, height/45,
             width - 2*width/45, height - 2*height/45, 0, 360*64);

    rects[0].x = 0;
    rects[0].y = 37*height/45;
    rects[0].width = width/3;
    rects[0].height = height - rects[0].y;

    rects[1].x = rects[0].width;
    rects[1].y = height/2;
    rects[1].width = width - 2*width/3;
    rects[1].height = height - rects[1].y;

    rects[2].x = 2*width/3;
    rects[2].y = height - 37*height/45;
    rects[2].width = width/3;
    rects[2].height = height - rects[2].y;

    XSetClipRectangles(dpy, gc, 0, 0, rects, 3, Unsorted);
    XFillRectangle(dpy, d, gc, 0, 0, width, height);

    XSetForeground(dpy, gc, whitePixel);
    XFillArc(dpy, d, gc, width/45, height/45,
             width - 2*width/45, height - 2*height/45, 0, 360*64);

    XFreeGC(dpy, gc);
}
#endif

