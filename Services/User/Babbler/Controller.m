#import "Controller.h"
#import "Player.h"
#import "StreamPanel.h"
#import <MultimediaKit/MPlayerInterface.h>

@implementation Controller
/** Private **/
- (void) newPlayer: (NSURL *) url
{
  /** Setup backend **/
  MPlayerInterface *mPlayer = [[MPlayerInterface alloc] init];
  [mPlayer setURL: url];

  NSRect frame = NSMakeRect(300, 500, 600, 100);
  Player *player = [[Player alloc] initWithContentRect: frame
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask
		            backing: NSBackingStoreRetained
			          defer: NO];
  [player setPlayer: mPlayer];
  [player makeKeyAndOrderFront: self];
  [players addObject: player];
}

/** End of Private **/

- (void) openFileAction: (id) sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  int result = [panel runModalForTypes: nil];
  if (result == NSOKButton) {
    NSArray *urls = [panel URLs];
    [self newPlayer: [urls objectAtIndex: 0]];
  }
}

- (void) openStreamAction: (id) sender
{
  StreamPanel *panel = [StreamPanel streamPanel];
  int result = [panel runModal];
  if (result == NSOKButton) {
    /* Check the validation of url */
    NSURL *url = [panel URL];
    if ([url scheme] == nil) {
      NSLog(@"Invalid URL: %@", url);
      return;
    }
    [self newPlayer: url];
  }
}

/**
 * Gets called when a file is dropped on the application icon.
 * The file is opened then.
 */
- (void) application: (NSApplication*) application
            openFile: (NSString*) fileName
{
  [self newPlayer: [NSURL fileURLWithPath: fileName]];
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
  /* Make menu */
  NSMenu *submenu, *menu = [[NSMenu alloc] initWithTitle: _(@"Babbler")];
  id <NSMenuItem> item;

  /* File */
  submenu = [[NSMenu alloc] initWithTitle: _(@"File")];
  [submenu addItemWithTitle: _(@"Open file...")
	   action: @selector(openFileAction:)
	   keyEquivalent: @"o"];
  [submenu addItemWithTitle: _(@"Open stream...")
	   action: @selector(openStreamAction:)
	   keyEquivalent: @"l"];
  item = [menu addItemWithTitle: _(@"File")
	       action: NULL
	       keyEquivalent: NULL];
  [menu setSubmenu: submenu forItem: item];
  DESTROY(submenu);
  
  /* Other */
  [menu addItemWithTitle: _(@"Hide")
	  action: @selector(hide:)
	  keyEquivalent: @"h"];
  [menu addItemWithTitle: _(@"Quit")
	  action: @selector(terminate:)
	  keyEquivalent: @"q"];

  [NSApp setMainMenu: AUTORELEASE(menu)];
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
  players = [[NSMutableArray alloc] init];
  
  NSArray *args = [[NSProcessInfo processInfo] arguments];
  if ([args count] > 1) {
    NSURL *url = [NSURL URLWithString: [args objectAtIndex: 1]];
    [self newPlayer: url];
  }
}

- (void) applicationWillTerminate: (NSNotification *) not
{
  /* Stop all players by closing them */
  NSEnumerator *e = [players objectEnumerator];
  Player *p = nil;
  while ((p = [e nextObject])) {
    [p performClose: self];
  }

  DESTROY(players);
}

@end

