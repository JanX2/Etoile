#import "Controller.h"
#import "OSFolderWindow.h"
#import "OSObjectFactory.h"
#import "OSTrashCan.h"
#import <InspectorKit/InspectorKit.h>

@implementation Controller

/* Action */
- (void) showHomeDirectory: (id) sender
{
  [self showObject: nil];
}

- (void) emptyTrashCan: (id) sender
{
  OSTrashCan *trashCan = [[OSObjectFactory defaultFactory] trashCan];
  [trashCan emptyTrashCan: sender];
  /* We trash can window is open, we close it */
  OSFolderWindow *window = [OSFolderWindow windowForObject: trashCan
                                     createNewIfNotExisted: YES];
  if (window)
    [window performClose: self];
}

/* */
- (void) showObject: (id <OSObject>) object
{
  OSFolderWindow *window = [OSFolderWindow windowForObject: object 
                                     createNewIfNotExisted: YES];
  if (window)
    [window makeKeyAndOrderFront: self];
}

- (id) init
{
  self = [super init];
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void)applicationWillFinishLaunching: (NSNotification *) not
{
  id <NSMenuItem> item = nil;
  NSMenu *menu = [[NSMenu alloc] initWithTitle: _(@"OuterSpace")];
  /* Info */
  NSMenu *submenu = [[NSMenu alloc] initWithTitle: _(@"Info")];
  [submenu addItemWithTitle: _(@"Info Panel...")
                     action: @selector(orderFrontStandardInfoPanel:)
              keyEquivalent: @""];

  item = [menu addItemWithTitle: _(@"Info")
                         action: NULL
                  keyEquivalent: @""];
  [menu setSubmenu: submenu forItem: item];
  DESTROY(submenu);

  submenu = [[NSMenu alloc] initWithTitle: _(@"Inspector")];
  item = [menu addItemWithTitle: _(@"Inspector")
                         action: NULL
                  keyEquivalent: @""];
  [menu setSubmenu: submenu forItem: item];
  [[Inspector sharedInspector] setInspectorMenu: submenu];
  DESTROY(submenu);

  [menu addItemWithTitle: _(@"Home")
                  action: @selector(showHomeDirectory:)
           keyEquivalent: @"H"];
  [menu addItemWithTitle: _(@"Empty Trash Can")
                  action: @selector(emptyTrashCan:)
           keyEquivalent: @""];

  submenu = [[NSMenu alloc] initWithTitle: _(@"Windows")];
  item = [menu addItemWithTitle: _(@"Windows")
                         action: NULL
                  keyEquivalent: @""];
  [menu setSubmenu: submenu forItem: item];
  [NSApp setWindowsMenu: submenu];
  DESTROY(submenu);

  [menu addItemWithTitle: _(@"Hide")
                  action: @selector(hide:)
           keyEquivalent: @"h"];
  [menu addItemWithTitle: _(@"Quit")
                  action: @selector(terminate:)
           keyEquivalent: @"q"];

  [NSApp setMainMenu: menu];
  DESTROY(menu);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
  /* Use default object. */
  [self showObject: nil];
}

- (BOOL)applicationShouldTerminate:(id)sender
{
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotif
{
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
  return NO;
}

@end

