#import "Controller.h"
#import "Player.h"
#import "StreamPanel.h"
#import <MultimediaKit/MPlayer.h>

@implementation Controller
/** Private **/
- (void) newPlayer: (NSURL *) url
{
  /** Setup backend **/
  MPlayer *mPlayer = [[MPlayer alloc] init];
  [mPlayer setURL: url];

  Player *player = [[Player alloc] init];
  [player setPlayer: mPlayer];
  [players addObject: player];
}

/** End of Private **/

- (void) openFile: (id) sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  int result = [panel runModalForTypes: nil];
  if (result == NSOKButton) {
    NSArray *urls = [panel URLs];
    [self newPlayer: [urls objectAtIndex: 0]];
  }
}

- (void) openStream: (id) sender
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
    [[p window] performClose: self];
  }

  DESTROY(players);
}

@end

