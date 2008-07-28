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

/* Proxy protocol to interact with session/workspace server */
@interface NSObject (SCSystem)
- (oneway void) logOut;
- (oneway void) powerOff: (BOOL) reboot;
- (oneway void) suspendComputer;
@end

@interface Controller (EtoileMenuServerPrivate)
- (void) applicationDidFinishLaunching: (NSNotification *) notif;
- (void) windowDidMove: (NSNotification *) notif;
- (id) _workspaceApp;
- (void) _reportSessionServerError: (NSString *)localizedOperation;
@end


@implementation Controller

MenuBarWindow * ServerMenuBarWindow = nil;

+ (MenuBarWindow *) sharedMenuBarWindow
{
  if (ServerMenuBarWindow == nil)
    {
      NSScreen * screen = [NSScreen mainScreen];
      NSRect screenFrame = [screen frame];
      NSRect frame = NSMakeRect(screenFrame.origin.x,
                               screenFrame.size.height - MenuBarHeight,
                               screenFrame.size.width,
                               MenuBarHeight);
      MenuBarView *view;

      ServerMenuBarWindow = [[MenuBarWindow alloc]
        initWithContentRect: frame
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreRetained
                      defer: NO];

      [ServerMenuBarWindow setTitle: _(@"EtoileMenuServer")];
      [ServerMenuBarWindow setCanHide: NO];
      [ServerMenuBarWindow setHidesOnDeactivate: NO];
#ifdef XWindowServerKit
      [ServerMenuBarWindow setDesktop: ALL_DESKTOP];
      [ServerMenuBarWindow skipTaskbarAndPager];
      [ServerMenuBarWindow setAsSystemDock];
      [ServerMenuBarWindow
        reserveScreenAreaOn: XScreenTopSide
                      width: MenuBarHeight
                      start: NSMinX(frame)
                        end: NSMaxX(frame)];

#endif
      view = AUTORELEASE([[MenuBarView alloc] initWithFrame: NSZeroRect]);
      [ServerMenuBarWindow setContentView: view];
      [ServerMenuBarWindow setLevel: NSMainMenuWindowLevel - 1];
    }

  return ServerMenuBarWindow;
}

- (void) applicationWillFinishLaunching: (NSNotification *) notif
{
  if ([[[NSProcessInfo processInfo] arguments] containsObject: @"--short"])
  {
    isShortFormat = YES;
  }
  else
  {
    isShortFormat = NO;
  }
}

- (void) applicationDidFinishLaunching: (NSNotification *) notif
{
  MenuletLoader *loader;

  // create the menu bar
  [[[self class] sharedMenuBarWindow] setDelegate: self];
  menuBarView = [ServerMenuBarWindow contentView];

  // and load all menulets
  loader = [MenuletLoader sharedLoader];
  [loader loadMenulets];

  if (isShortFormat == YES)
  {
     /* Shrink it */
     int width = [loader width] + [menuBarView minimalSize].width+2;
     NSRect frame = [ServerMenuBarWindow frame];
     frame.origin.x = frame.size.width-width;
     frame.size.width = width;
     [ServerMenuBarWindow setFrame: frame display: NO];
  }

  [loader organizeMenulets];

  [ServerMenuBarWindow orderFront: nil];
}

- (void) windowDidMove: (NSNotification *) notif
{
  NSScreen * screen = [NSScreen mainScreen];
  NSRect screenFrame = [screen frame];
  NSRect windowFrame = [ServerMenuBarWindow frame];
  NSRect correctFrame = NSMakeRect(screenFrame.origin.x,
                                  screenFrame.size.height - MenuBarHeight,
                                  screenFrame.size.width,
                                  MenuBarHeight);

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
  NSAlert *alert = nil;
  NSString *explanation = _(@"If you log out, you may be asked to review open documents with unsaved changes.");
  int reply;

#if 0
  alert = [NSAlert alertWithMessageText: _(@"Are sure you want to log out now?")
                          defaultButton: _(@"Log Out")
                        alternateButton: _(@"Cancel")
                            otherButton: nil
              informativeTextWithFormat: explanation];
  reply = [alert runModal];
#endif
  reply = NSRunAlertPanel (_(@"Are sure you want to log out now?"), explanation, 
    _(@"Log Out"), _(@"Cancel"), nil);

  if (reply == NSAlertDefaultReturn)
    {
      NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
      id sessionApp = [self _workspaceApp];

      if (sessionApp != nil)
        {
          NS_DURING
           [sessionApp logOut];
          NS_HANDLER
            NSString * msgText = _(@"Log out cannot be carried out.");
            NSString * infoText = [localException reason];

            NSRunAlertPanel (nil, msgText, infoText, nil, nil);
          NS_ENDHANDLER
        }
      else
        {
          [self _reportSessionServerError: _(@"Log out")];
        }
    }
}

- (void) sleep: sender
{
  NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
  id sessionApp = [self _workspaceApp];

  if (sessionApp != nil)
    {
      NS_DURING
       [sessionApp suspendComputer];
      NS_HANDLER
        NSString * msgText = _(@"Sleep failed.");
        NSString * infoText = [localException reason];

        NSRunAlertPanel (msgText, infoText, nil, nil, nil);
      NS_ENDHANDLER
    }
  else
    {
      [self _reportSessionServerError: _(@"Sleep")];
    }
}

- (void) reboot: sender
{
  NSAlert *alert = nil;
  NSString *explanation = _(@"If you reboot, you may be asked to review open documents with unsaved changes.");
  int reply;

#if 0
  alert = [NSAlert alertWithMessageText: _(@"Are sure you want to reboot now?")
                          defaultButton: _(@"Reboot")
                        alternateButton: _(@"Cancel")
                            otherButton: nil
              informativeTextWithFormat: explanation];
  reply = [alert runModal];
#endif
  reply = NSRunAlertPanel (_(@"Are sure you want to reboot now?"), explanation, 
    _(@"Reboot"), _(@"Cancel"), nil);

  if (reply == NSAlertDefaultReturn)
    {
      NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
      id sessionApp = [self _workspaceApp];

      if (sessionApp != nil)
        {
NSLog(@"hmm reboot");
          NS_DURING
            [sessionApp powerOff: YES];
          NS_HANDLER
            NSString * msgText = _(@"Reboot cannot be carried out.");
            NSString * infoText = [localException reason];

            NSRunAlertPanel (msgText, infoText, nil, nil, nil);
          NS_ENDHANDLER
        }
      else
        {
          [self _reportSessionServerError: _(@"Reboot")];
        }
    }
}

- (void) shutDown: sender
{
  NSAlert *alert = nil;
  NSString *explanation = _(@"If you shut down, you may be asked to review open documents with unsaved changes.");
  int reply;

#if 0
  alert = [NSAlert alertWithMessageText: _(@"Are sure you want to shut down now?")
                          defaultButton: _(@"Shut Down")
                        alternateButton: _(@"Cancel")
                            otherButton: nil
              informativeTextWithFormat: explanation];
  reply = [alert runModal];
#endif
  reply = NSRunAlertPanel (_(@"Are sure you want to shut down now?"), explanation, 
    _(@"Shut Down"), _(@"Cancel"), nil);


  if (reply == NSAlertDefaultReturn)
    {
      NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
      id sessionApp = [self _workspaceApp];

      if (sessionApp != nil)
        {
          NS_DURING
            [sessionApp powerOff: NO];
          NS_HANDLER
            NSString * msgText = _(@"Shut down cannot be carried out.");
            NSString * infoText = [localException reason];

            NSRunAlertPanel (msgText, infoText, nil, nil, nil);
          NS_ENDHANDLER
        }
      else
        {
          [self _reportSessionServerError: _(@"Shut down")];
        }
    }
}

- (id) _workspaceApp
{
  return [[NSWorkspace sharedWorkspace] connectToWorkspaceApplicationLaunch: NO];
}

// TODO: May be better to pass an NSError instance rather than a simple string.
- (void) _reportSessionServerError: (NSString *)localizedOperation
{
  NSString * msgText = _(@" failed. No session server is available.");
  NSString * infoText = _(@"Etoile is in a very unstable state. You should review your open documents with unsaved changes, then try to force log out or reboot your computer.");

  msgText = [localizedOperation stringByAppendingString: msgText];

  /* If System dies, it should normally bring the whole session down 
     with him. Thereby this problem should't happen. */

  NSRunAlertPanel(msgText, infoText, nil, nil, nil);
}

@end

@implementation NSApplication (EtoileMenuBar)

/* Useful for EtoileWildMenus which requests our position and size through DO 
   thanks to this method. */
- (NSRect) menuBarWindowFrame
{
  NSLog(@"%@", NSStringFromRect([ServerMenuBarWindow frame]));
  return [ServerMenuBarWindow frame];
}

@end
