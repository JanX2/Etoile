// FIXME: When you take in account System can be use without any graphical UI 
// loaded, linking AppKit by default is bad,thne  put this stuff in a bundle 
// and load it only when necessary. Or may be put this stuff in another daemon.

#import "Controller.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ApplicationManager.h"
#import "EtoileSystem.h"

NSString * const EtoileWorkspaceServerAppName = @"EtoileWorkspaceServer";

@implementation Controller

- (void) applicationDidFinishLaunching: (NSNotification *) notif
{
  // this one must go first, so we certainly catch all processes
  [ApplicationManager sharedInstance];

  //[SCSystem sharedInstance];
}

- (BOOL) openFile: (NSString *) aFile
  withApplication: (NSString *) appName
    andDeactivate: (BOOL) deactivate
{
  return [[NSWorkspace sharedWorkspace]
    openFile: aFile withApplication: appName andDeactivate: deactivate];
}

- (NSArray *) launchedApplications
{
  return [[ApplicationManager sharedInstance] launchedApplications];
}

- (oneway void) logOutAndPowerOff: (BOOL) powerOff
{
  NSString * operation;

  if (powerOff == NO)
    {
      operation = _(@"Log Out");
    }
  else
    {
      operation = _(@"Power Off");
    }

  // close all apps and aftewards workspace processes gracefully
    if ([[ApplicationManager shared]
      gracefullyTerminateAllApplicationsOnOperation: operation] &&
      [[SCSystem serverInstance]
      gracefullyTerminateAllProcessesOnOperation: operation])
    {
      if (powerOff)
        {
          // TODO - initiate the power off process here
        }

      // and go away
      [NSApp terminate: self];
    }
}

@end
