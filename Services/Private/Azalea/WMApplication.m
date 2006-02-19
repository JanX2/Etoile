/* Desktop.m
 *  
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: May 2004
 *
 * This file is part of the GNUstep Desktop application
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <AppKit/AppKit.h>
#include "WMApplication.h"	
#include "WMDialogController.h"
#include "WMWindowInspector.h"
#include "WMDefaults.h"
#include <X11/Xlib.h>

#include <unistd.h>
#include "WINGs/wconfig.h"
#include "funcs.h"
#include "actions.h"
#include "screen.h"
#include "window.h"
#include "framewin.h"
#include "session.h"
#include "workspace.h"
#include "X11/Xlocale.h"

extern Display *dpy;
extern void W_InitNotificationCenter(void);

static WMApplication *wmapp = nil;

int WMCurrentScreen()
{
  // FIXME: try to figure out which screen the menu is called.
  NSView *view = [[NSApp mainMenu] menuRepresentation];
  NSScreen *screen = [[view window] screen];
  return [screen screenNumber];
}

@interface WMApplication (WMPrivate)
- (void) updateWorkspacesMenu;
- (void) updateSwitchMenu;
@end

@implementation WMApplication

+ (WMApplication *) wmApplication
{
  if (wmapp == nil) 
  {
    wmapp = [[WMApplication alloc] init];
  }	
  return wmapp;
}

- (id) init
{
  self = [super init];
  
  if (self) 
  {
  }
  
  return self;
}

- (void) dealloc
{      
  DESTROY(applicationName);
  [super dealloc];
}

- (void) initializeWithName: (NSString *) name
          numberOfArguments: (int *)argc
                  arguments: (char **)argv
{
  int i;

  assert(argc!=NULL);
  assert(argv!=NULL);
  assert(name!=nil);

  setlocale(LC_ALL, "");

#ifdef I18N
  if (getenv("NLSPATH"))
    bindtextdomain("WINGs", getenv("NLSPATH"));
  else
    bindtextdomain("WINGs", LOCALEDIR);
  bind_textdomain_codeset("WINGs", "UTF-8");
#endif

  ASSIGN(applicationName, [NSString stringWithCString: argv[0]]);

  WMApp.applicationName = wstrdup((char*)[applicationName cString]);
  WMApp.argc = *argc;
  WMApp.argv = wmalloc((*argc+1)*sizeof(char*));
  for (i=0; i<*argc; i++) {
    WMApp.argv[i] = wstrdup(argv[i]);
  }
  WMApp.argv[i] = NULL;

  /* initialize notification center */
  W_InitNotificationCenter();
}

- (BOOL) isApplicationInitialized
{
  return (applicationName != nil);
}

- (NSString *) applicationName
{
  return [NSString stringWithCString: WMApp.applicationName];
}

- (void)receivedEvent:(void *)data
                 type:(RunLoopEventType)type
                extra:(void *)extra
              forMode:(NSString *)mode
{
  XEvent event;

  while (XPending(dpy)) {
    WMNextEvent(dpy, &event);
    WMHandleEvent(&event);
  }
}

- (void) createMenu
{
  NSMenu *mainMenu;
  NSMenu *info, *execute, *arrange;
  NSMenu *windows, *services, *session;
  NSMenuItem *item;

  mainMenu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"WMaker"]);

  /* Info */
  info = AUTORELEASE([[NSMenu alloc] init]);
  [info addItemWithTitle: @"Info Panel..."
	          action: @selector(orderFrontStandardInfoPanel:)
	   keyEquivalent: @"i"];
  [info addItemWithTitle: @"Info..."
	          action: @selector(showInfoPanel:)
	   keyEquivalent: @""];
  [info addItemWithTitle: @"About GNUstep..."
	          action: @selector(showGNUstepPanel:)
	   keyEquivalent: @""];
  [info addItemWithTitle: @"Legal..."
	          action: @selector(showLegalPanel:)
	   keyEquivalent: @""];
  [info addItemWithTitle: @"Window Inspector..."
	          action: @selector(showWindowInspector:)
	   keyEquivalent: @""];
  item = [mainMenu addItemWithTitle: @"Info" 
	                     action: NULL keyEquivalent: @""];
  [mainMenu setSubmenu: info forItem: item];

  /* Execute */
  execute = AUTORELEASE([[NSMenu alloc] init]);
  [execute addItemWithTitle: @"External Program..."
	                action: @selector(executeExternalProgram:)
                 keyEquivalent: @""];
  [execute addItemWithTitle: @"Shell Command..."
	                action: @selector(executeShellCommand:)
                 keyEquivalent: @""];
  item = [mainMenu addItemWithTitle: @"Execute" 
	                     action: NULL keyEquivalent: @""];
  [mainMenu setSubmenu: execute forItem: item];

  /* Workspaces */
  workspacesMenu = AUTORELEASE([[NSMenu alloc] init]);
  [workspacesMenu addItemWithTitle: @"New Workspace"
	                action: @selector(newWorkspace:)
                 keyEquivalent: @""];
  [workspacesMenu addItemWithTitle: @"Destroy Last Workspace"
	                action: @selector(destroyLastWorkspace:)
                 keyEquivalent: @""];
  [workspacesMenu addItemWithTitle: @"Rename  Workspace"
	                action: @selector(renameWorkspace:)
                 keyEquivalent: @""];
  item = [mainMenu addItemWithTitle: @"Workspaces" 
	                     action: NULL  keyEquivalent: @""];
  [mainMenu setSubmenu: workspacesMenu forItem: item];

  /* Arrange */
  arrange = AUTORELEASE([[NSMenu alloc] init]);
  [arrange addItemWithTitle: @"Hide Others"
	             action: @selector(hideOthers:)
              keyEquivalent: @""];
  [arrange addItemWithTitle: @"Show All"
	             action: @selector(showAll:)
              keyEquivalent: @""];
  [arrange addItemWithTitle: @"Refresh"
	             action: @selector(refresh:)
              keyEquivalent: @""];
  [arrange addItemWithTitle: @"Arrange Icons"
	             action: @selector(arrangeIcons:)
              keyEquivalent: @""];
  item = [mainMenu addItemWithTitle: @"Arrange" 
	                     action: NULL keyEquivalent: @""];
  [mainMenu setSubmenu: arrange forItem: item];

  /* Switches
   * Although this should be windows menu,
   * now, it is better not to mix them
   * because one is controlled by GNUstep 
   * and the other is by WMaker.
   */
  switches = AUTORELEASE([[NSMenu alloc] init]);
  item = [mainMenu addItemWithTitle: @"Switch" 
	                     action: NULL keyEquivalent: @""];
  [mainMenu setSubmenu: switches forItem: item];

  /* Windows */
  windows = AUTORELEASE([[NSMenu alloc] init]);
  item = [mainMenu addItemWithTitle: @"Windows" 
	                     action: NULL keyEquivalent: @""];
  [mainMenu setSubmenu: windows forItem: item];

  /* Services */
  services = AUTORELEASE([[NSMenu alloc] init]);
  item = [mainMenu addItemWithTitle: @"Services" 
	                     action: NULL keyEquivalent: @""];
  [mainMenu setSubmenu: services forItem: item];

#if 0
  /* Debug */
  NSMenu *debug = AUTORELEASE([[NSMenu alloc] init]);
  [debug addItemWithTitle: @"Open Window"
	             action: @selector(debugWindow:)
              keyEquivalent: @""];
  item = [mainMenu addItemWithTitle: @"Debug" 
	                     action: NULL keyEquivalent: @""];
  [mainMenu setSubmenu: debug forItem: item];
#endif
  /* Debug */
  session = AUTORELEASE([[NSMenu alloc] init]);
  [session addItemWithTitle: @"Save Session"
	             action: @selector(saveSession:)
              keyEquivalent: @""];
  [session addItemWithTitle: @"Clear Session"
	             action: @selector(clearSession:)
              keyEquivalent: @""];
  [session addItemWithTitle: @"Restart Window Maker"
	             action: @selector(restartWindowMaker:)
              keyEquivalent: @""];
  [session addItemWithTitle: @"Restart"
	             action: @selector(restart:)
              keyEquivalent: @""];
  [session addItemWithTitle: @"Shutdown..."
	             action: @selector(shutdown:)
              keyEquivalent: @""];
  [session addItemWithTitle: @"Exit..."
	             action: @selector(exit:)
              keyEquivalent: @""];
  item = [mainMenu addItemWithTitle: @"Session" 
	                     action: NULL keyEquivalent: @""];
  [mainMenu setSubmenu: session forItem: item];

  [NSApp setServicesMenu: services];
  [NSApp setWindowsMenu: windows];
  [NSApp setMainMenu: mainMenu];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
  /* Create menu */
  [self createMenu];

  /* Listen event */
  NSRunLoop	*loop = [NSRunLoop currentRunLoop];
  int xEventQueueFd = XConnectionNumber(dpy);
  
  [loop addEvent: (void*)(gsaddr)xEventQueueFd
		        type: ET_RDESC
		     watcher: (id<RunLoopEvents>)self
		     forMode: NSDefaultRunLoopMode];  
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  /* Make sure the workspace is updated */
  [self updateWorkspacesMenu];
  
  /* Make sure switch menu is updated */
  [self updateSwitchMenu];
}

- (BOOL)applicationShouldTerminate:(NSApplication *)app 
{
	return YES;
}

/* Execute */

/* from execCommand() of rootmenu */
- (void) execute: (NSString *) command
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    /* FIXME: not sure to grab pointer and cursor
     XGrabPointer(dpy, menu->frame->screen_ptr->root_win, True, 0,
                GrabModeAsync, GrabModeAsync, None, wCursor[WCUR_WAIT],
                CurrentTime);
     XSync(dpy, 0);
     */
    if (command)
    {
      char *cmdline = wstrdup((char*)[command cString]);
      ExecuteShellCommand(scr, cmdline);
      wfree(cmdline);
    }
    /*
     XUngrabPointer(dpy, CurrentTime);
     XSync(dpy, 0);
     */
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
		    
}

- (void) executeExternalProgram: (id) sender
{
  NSString *command = [[WMDialogController sharedController]
	    inputDialogWithTitle: @"Execute"
	    message: @"Execute external program" text: nil];
  if (command && [command length])
    [self execute: [NSString stringWithFormat: @"exec %@", command]];
}

- (void) executeShellCommand: (id) sender
{
  NSString *command = [[WMDialogController sharedController]
	    inputDialogWithTitle: @"Execute"
	    message: @"Execute external program" text: nil];
  if (command && [command length])
    [self execute: command];
}

/* Workspaces */

- (void) newWorkspace: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    int ws = wWorkspaceNew(scr);
    [self updateWorkspacesMenu];
    /* autochange workspace */
    if (ws >= 0)
      wWorkspaceChange(scr, ws);
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

- (void) destroyLastWorkspace: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    wWorkspaceDelete(scr, scr->workspace_count-1);
    [self updateWorkspacesMenu];
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

- (void) switchWorkspace: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    int d = 3; // default workspace menu: new, destroy, rename
    int index = [workspacesMenu indexOfItem: sender];
    if (index != NSNotFound)
      wWorkspaceChange(scr, index-d);
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

- (void) renameWorkspace: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    int wspace = scr->current_workspace;
    int d = 3; // default workspace menu: new, destroy, rename
    char *name = wstrdup(scr->workspaces[wspace]->name);
    NSString *text = [NSString stringWithCString: name];
    NSString *string = [NSString stringWithFormat: @"Type the name for workspace %i:", wspace];
    NSString *new_name = [[WMDialogController sharedController]
	    inputDialogWithTitle: @"Rename Workspace"
	    message: string text: text];
    if (new_name)
    {
      char *n = wstrdup((char*)[new_name cString]);
      wWorkspaceRename(scr, wspace, n);
      /* rename menu item */
      NSMenuItem *item = [workspacesMenu itemAtIndex: wspace+d];
      [item setTitle: new_name];
      [workspacesMenu itemChanged: item];
      if (n) 
      {
        wfree(n);
      }
    }
    if (name)
    {
      wfree(name);
    }
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

/* Switches */
- (NSMenu *) switchMenu
{
  return switches;
}

- (void) switchWindow: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    /* FIXME: it assumes the client from WWindow is unique */
    int client = [sender tag];
    WWindow *wwin = scr->focused_window;
    while (wwin) {
      if (wwin->client_win == client)
      {
        /* from focusWindow() in switchmenu.c */
	int x, y, move = 0;

	wMakeWindowVisible(wwin);

	x = wwin->frame_x;
	y = wwin->frame_y;

	/* bring window back to visible area */
	move = wScreenBringInside(scr, &x, &y, wwin->frame->core->width,
			wwin->frame->core->height);

	if (move) {
	  wWindowConfigure(wwin, x, y, wwin->client.width, wwin->client.height);
	}
	break;
      }
      wwin = wwin->prev;
    }
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

/* Windows */

- (void) refresh: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    wRefreshDesktop(scr);
    /* FIXME: doesn't really work
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[WMDefaults sharedDefaults] readDefaults: scr];
    */
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

- (void) arrangeIcons: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    wArrangeIcons(scr, True);
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

- (void) showAll: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    wShowAllWindows(scr);
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}
- (void) hideOthers: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    wHideOtherApplications(scr->focused_window);
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}


/* Session */
- (void) saveSession: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    if (!wPreferences.save_session_on_exit)
      wSessionSaveState(scr);

    wScreenSaveState(scr);
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

- (void) clearSession: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    wSessionClearState(scr);
    wScreenSaveState(scr);
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

- (void) restartWindowMaker: (id) sender
{
  Shutdown(WSRestartPreparationMode);
  Restart("wmaker", False);
  Restart(NULL, True);
}

/* restartCommand() in rootmenu.c */
- (void) restart: (id) sender
{
  Shutdown(WSRestartPreparationMode);
  Restart(NULL, False);
  Restart(NULL, True);
}

/* shutdowCommand() in rootmenu.c */
- (void) shutdown: (id) sender
{
#define R_CANCEL 0
#define R_CLOSE 1
#define R_KILL 2
  int result;
#ifdef XSMP_ENABLED
  if (wSessionIsManaged()) {
    int r;
    r = [[WMDialogController sharedController] exitDialogWithTitle: @"Close X session"
      message: @"Close Window System session?\nKill might close apploications with unsaved data."
	      defaultButton: @"Close"
	      alternateButton: @"Kill"
	      otherButton: @"Cancel"];
    switch(r) {
	    case NSAlertDefaultReturn:
              result = R_CLOSE;
	      break;
	    case NSAlertAlternateReturn:
	      result = R_KILL;
	      break;
	    default:
	      result = R_CANCEL;
    }
  } else
#endif
  {
    int r, oldSaveSessionFlag;

    oldSaveSessionFlag = wPreferences.save_session_on_exit;

    r = [[WMDialogController sharedController] exitDialogWithTitle: @"Kill X session"
    message: @"Kill Window System session?\n all applications will be closed."
	      defaultButton: @"Kill"
	      alternateButton: @"Cancel"
	      otherButton: nil];
    switch(r) {
	    case NSAlertDefaultReturn:
              result = R_KILL;
	      break;
	    default:
	      wPreferences.save_session_on_exit = oldSaveSessionFlag;
	      result = R_CANCEL;
    }
  }
  if (result!=R_CANCEL) {
#ifdef XSMP_ENABLED
    if (result == R_CLOSE) {
      Shutdown(WSLogoutMode);
    } else
#endif /* XSMP_ENABLED */
    {
      Shutdown(WSKillMode);
    }
  }
#undef R_CLOSE
#undef R_CANCEL
#undef R_KILL
}

/* exitCommand() in rootmenu.c */
- (void) exit: (id) sender
{
  int r, oldSaveSessionFlag;

  oldSaveSessionFlag = wPreferences.save_session_on_exit;
  r = [[WMDialogController sharedController] exitDialogWithTitle: @"Exit"
	                                  message: @"Exit window manager ?"
			 	    defaultButton: @"Exit"
                                  alternateButton: @"Cancel"
                                      otherButton: nil];

  if (r == NSAlertDefaultReturn) {
    /* Exiting */
	  Shutdown(WSExitMode);
  } else {
    /* Put save session back */
    wPreferences.save_session_on_exit = oldSaveSessionFlag;
  }
}

/* Info */
- (void) showGNUstepPanel: (id) sender
{
  [[WMDialogController sharedController] showGNUstepPanel: self];
}

- (void) showInfoPanel: (id) sender
{
  [[WMDialogController sharedController] showInfoPanel: self];
}

- (void) showLegalPanel: (id) sender
{
  [[WMDialogController sharedController] showLegalPanel: self];
}

- (void) showWindowInspector: (id) sender
{
  [[WMWindowInspector sharedWindowInspector] makeKeyAndOrderFront: self];
}

/** Debug **/

- (void) windowWillClose: (NSNotification *) not
{
}

- (void) debugWindow: (id) sender
{
//  [[WMDialogController sharedController] showTestWindow: self];
}

/** Private **/

/* This only update the number of workspace.
 * It won't deal with the rename of workspace.
 */
- (void) updateWorkspacesMenu
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    int d = 3; // number of items in menu (new, destroy, rename) 
    int i, ws, num = [workspacesMenu numberOfItems];
    if (num < scr->workspace_count+d)
    {
      /* new workspace(s) added */
      ws = num-d;
      i = scr->workspace_count-ws;
      NSString *title;
      while (i > 0) {
	char *n = wstrdup(scr->workspaces[ws]->name);
	title = [NSString stringWithCString: n];
	[workspacesMenu addItemWithTitle: title
		action: @selector(switchWorkspace:)
		keyEquivalent: @""];
        i--;
	ws++;
	// FIXME: not sure to free n because it is used by NSString.
	// wfree(n)
      }
    }
    else if (num > scr->workspace_count+d)
    {
      /* removed workspace(s) */
      for (i = num-1; i >= scr->workspace_count+d; i--)
      {
        [workspacesMenu removeItemAtIndex: i];
      }
    }
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

/* This is usually called at the first time for switch menu */
- (void) updateSwitchMenu
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    /* Remove all menu items */
    while ([switches numberOfItems])
    {
      [switches removeItemAtIndex: 0];
    }

    /* from OpenSwitchMenu() in switchmenu.c */
    WWindow *wwin = scr->focused_window;
    while (wwin) {
      UpdateSwitchMenu(scr, wwin, ACTION_ADD);

      wwin = wwin->prev;
    }
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

@end
