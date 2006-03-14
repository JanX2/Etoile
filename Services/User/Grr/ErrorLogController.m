/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "ErrorLogController.h"

#import "MainController.h"

ErrorLogController* inst;

@implementation ErrorLogController

+(ErrorLogController*) instance {
  if (inst == nil) {
    inst = [[ErrorLogController alloc] init];
  }
  
  return inst;
}

-init
{
  self = [super init];
  if (self != nil) {
    inst = self;
    [getMainController() errorLogController: self];
  }
  
  return self;
}

/**
 * Clear the log window. Only execute this from the main
 * thread!
 */
- (void) clearLog: (id)sender
{
  // usually called directly from the GUI, I assume it's executed from
  // the main thread.
  [logWidget setString: @""];
}

/**
 * Don't call this! It's 'private' and may break stuff when called directly.
 * Use the thread-safe logString: method instead.
 */
- (void) _logStringInMainThread: (NSString*) aString
{
  [logWidget
    setString: [[logWidget string] stringByAppendingString: aString]];
  [logWidget display];
  
  // Finally we don't need the string any more.
  RELEASE(aString);
  
  [logWindow orderFront: self];
}

/**
 * Logs a string to the log window.
 */
- (void) logString: (NSString*) aString
{
  RETAIN(aString); // Needed to be held (seems not to be done by GS)
  [self performSelectorOnMainThread: @selector(_logStringInMainThread:)
	withObject: aString
	waitUntilDone: NO];
}

@end
