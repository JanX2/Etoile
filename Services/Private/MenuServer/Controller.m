/*
    Controller.m

    Implementation of the Controller class for the EtoileMenuServer
    application.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "Controller.h"

#import <Foundation/NSConnection.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSException.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSUserDefaults.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSWorkspace.h>

#import <WorkspaceCommKit/NSWorkspace+Communication.h>

#import "MenuBarHeight.h"
#import "MenuBarView.h"
#import "MenuBarWindow.h"
#import "MenuletLoader.h"

static inline int
my_round (float x)
{
  return (int) (x + 0.5);
}

@interface NSObject (WorkspaceAppInterface)

- (oneway void) logOutAndPowerOff: (BOOL) powerOff;

@end

@implementation Controller

MenuBarWindow * ServerMenuBarWindow = nil;

+ (NSRect) menuBarWindowFrame
{
  NSScreen * screen = [NSScreen mainScreen];
  NSRect screenFrame;

  screenFrame = [screen frame];
  return NSMakeRect(screenFrame.origin.x,
    screenFrame.size.height - MenuBarHeight, screenFrame.size.width,
    MenuBarHeight);
}

+ (MenuBarWindow *) sharedMenuBarWindow
{
  if (ServerMenuBarWindow == nil)
    {
      MenuBarView * menuBarView;

      ServerMenuBarWindow = [[MenuBarWindow alloc]
        initWithContentRect: [self menuBarWindowFrame]
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreRetained
                      defer: NO];

      [ServerMenuBarWindow setTitle: _(@"EtoileMenuServer")];
      [ServerMenuBarWindow setCanHide: NO];
      [ServerMenuBarWindow setHidesOnDeactivate: NO];
#ifdef XWindowServerKit
      [ServerMenuBarWindow setDesktop: ALL_DESKTOP];
      [ServerMenuBarWindow skipTaskbarAndPager];
      [ServerMenuBarWindow
        reserveScreenAreaOn: XScreenTopSide
                      width: MenuBarHeight
                      start: 0
                        end: [self menuBarWindowFrame].size.width];

#endif

      menuBarView = [[[MenuBarView alloc]
        initWithFrame: NSZeroRect]
        autorelease];
      [ServerMenuBarWindow setContentView: menuBarView];

      [ServerMenuBarWindow setLevel: NSMainMenuWindowLevel - 1];
    }

  return ServerMenuBarWindow;
}

- (void) applicationDidFinishLaunching: (NSNotification *) notif
{
  // create the menu bar
  [[[self class] sharedMenuBarWindow] setDelegate: self];

  // and load all menulets
  [[MenuletLoader shared] loadMenulets];

  [ServerMenuBarWindow orderFront: nil];
}

- (void) windowDidMove: (NSNotification *) notif
{
  NSRect windowFrame = [ServerMenuBarWindow frame],
         correctFrame = [Controller menuBarWindowFrame];

  NSDebugLLog(@"MenuServer", @"Menu window did move: %@", notif);

  // convert to make sure we display correctly even with a buggy
  // window manager which doesn't honour our settings to not display
  // any window decorations
  correctFrame = [NSWindow frameRectForContentRect: correctFrame
                                         styleMask: NSBorderlessWindowMask];

  if (!NSEqualRects (windowFrame, correctFrame))
    {
      // get the menu bar back in place in case the user somehow moved it

      // FIXME: We should reset the frame only when it is possible (no other 
      // top menu present like in GNOME or KDE environment). Turned off in the 
      // meantime else it quickly takes over CPU by constantly calling this
      // notification.
      //[ServerMenuBarWindow setFrame: correctFrame display: YES];
    }
}

// action which contacts the workspace app and asks it to initiate
// a log out operation
- (void) logOut: sender
{
  int reply;

  reply = NSRunAlertPanel (_(@"Really log out?"),
    _(@"Are sure you want to log out?"),
    _(@"Log Out"), _(@"Power Off"), _(@"Cancel"));

  if (reply == NSAlertDefaultReturn || reply == NSAlertAlternateReturn)
    {
      NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
      id workspaceApp;

      workspaceApp = [self workspaceApp];

      if (workspaceApp != nil)
        {
          NS_DURING
            [workspaceApp logOutAndPowerOff: reply];
          NS_HANDLER
            NSRunAlertPanel (_(@"Failed to log out"),
              _(@"Failed to initiate log out operation: %@"),
              nil, nil, nil, [localException reason]);
          NS_ENDHANDLER
        }
      else
        {
          NSRunAlertPanel(_(@"Failed to contact workspace"),
            _(@"Failed to contact workspace application."),
            nil, nil, nil);
        }
    }
}

- (void) sleep: sender
{
	// TODO
}

- (void) reboot: sender
{
	// TODO
}

- (void) shutDown: sender
{
	// TODO
}

- (id) workspaceApp
{
  return [[NSWorkspace sharedWorkspace] connectToWorkspaceApplicationLaunch: NO];
}

@end

@implementation NSApplication (EtoileMenuBar)

/* Useful for EtoileWildMenus which requests our position and size through DO 
   thanks to this method. */
- (NSRect) menuBarWindowFrame
{
  return [Controller menuBarWindowFrame];
}

@end
