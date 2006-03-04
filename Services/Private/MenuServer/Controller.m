
#import "Controller.h"

#import <AppKit/NSScreen.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenu.h>

#import "MenuBarHeight.h"
#import "MenuBarWindow.h"
#import "MenuBarView.h"
#import "MenuletLoader.h"

static inline int my_round(float x)
{
  return (int) (x + 0.5);
}

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
                      defer: YES];

      [ServerMenuBarWindow setCanHide: NO];
      [ServerMenuBarWindow setHidesOnDeactivate: NO];

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

  // and load all docklets
  [[MenuletLoader shared] loadMenulets];

  [ServerMenuBarWindow orderFront: nil];
}

- (void) windowDidMove: (NSNotification *) notif
{
  // get the menu bar back in place in case the user somehow moved it
  [ServerMenuBarWindow setFrame: [Controller menuBarWindowFrame] display: YES];
}

@end
