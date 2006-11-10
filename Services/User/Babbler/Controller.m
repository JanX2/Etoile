#import "Controller.h"
#import "Player.h"
#import <MultimediaKit/MPlayerInterface.h>

@implementation Controller
/** Private **/
- (void) newPlayer: (NSURL *) url
{
  /** Setup backend **/
  MPlayerInterface *mPlayer = [[MPlayerInterface alloc] init];
  [mPlayer setURL: url];

  NSRect frame = NSMakeRect(300, 500, 400, 100);
  Player *player = [[Player alloc] initWithContentRect: frame
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask
		            backing: NSBackingStoreRetained
			          defer: NO];
  [player setPlayer: mPlayer];
  [player makeKeyAndOrderFront: self];
  [players addObject: player];
}

/** End of Private **/

- (void) openAction: (id) sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  int result = [panel runModalForTypes: nil];
  if (result == NSOKButton) {
    NSArray *urls = [panel URLs];
    [self newPlayer: [urls objectAtIndex: 0]];
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
  NSMenu *menu = [[NSMenu alloc] init];
  [menu addItemWithTitle: @"Open file..."
	  action: @selector(openAction:)
	  keyEquivalent: @"o"];
  [menu addItemWithTitle: @"Hide"
	  action: @selector(hide:)
	  keyEquivalent: @"h"];
  [menu addItemWithTitle: @"Quit"
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

