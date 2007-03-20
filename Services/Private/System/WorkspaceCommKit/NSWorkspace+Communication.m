
#import "NSWorkspace+Communication.h"

#import <Foundation/NSConnection.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>

/**
 * Extensions to the NSWorkspace class to add inter-application
 * communication. This is extensively used in the Etoile desktop
 * environment between applications providing the various workspace
 * services.
 */
@implementation NSWorkspace (WorkspaceComm)

/**
 * Contacts a specified application, launching it if requested.
 *
 * @param appName The application which to contact.
 * @param launchFlag Specifies that if the application isn't
 *      already running, it should be launched.
 *
 * @return A remote connection object to the application, or `nil'
 *      if the application could not be contacted (either because
 *      of not running or because it could not be launched).
 */
- connectToApplication: (NSString *) appName
                launch: (BOOL) launchFlag
{
  // NOTE: Using [[NSHost currentHost] name]; would make the root proxy lookup 
  // fails, because to reference NSSMessagePortNameServer on GNUstep you must
  // passs either nil or an empty string (which match the local host).
  NSString * hostName = nil; 
  id app;

  app = [NSConnection rootProxyForConnectionWithRegisteredName: appName
                                                          host: hostName];
  if (app == nil && launchFlag == YES)
    {
      NSDate * start;
      float timeout;

      // app not running, try to launch it
      if (![self launchApplication: appName])
        {
          return nil;
        }

      start = [NSDate date];

      // see how long at most we should wait for the app to
      // finish starting up
      timeout = [[NSUserDefaults standardUserDefaults]
        floatForKey: @"EtoileAppConnectTimeout"];
      if (timeout < 1)
        {
          timeout = 10;
        }

      while (app == nil &&
             [[NSDate date] timeIntervalSinceDate: start] <= timeout)
        {
          // check every 0.5 seconds
          [[NSRunLoop currentRunLoop] runUntilDate: [NSDate
            dateWithTimeIntervalSinceNow: 0.5]];

          app = [NSConnection
            rootProxyForConnectionWithRegisteredName: appName host: hostName];
        }
    }

  return app;
}

/**
 * Attempts to connect to the workspace manager application (defaults
 * to "EtoileWorkspaceServer" if no GSWorkspaceApplication user default
 * is specified).
 *
 * @param launchFlag A flag which specifies whether the workspace app
 *      should be launched if necessary.
 */
- connectToWorkspaceApplicationLaunch: (BOOL) launchFlag
{
  NSString * appName = nil;

#if 0 
  /* It does not make sense to check for default workspace
     because even if there is one, we still use etoile_system to log out.
     And in order to avoid GWorkspace from launching automatically,
     we may set GSWorkspaceApplication to a non-existing application.
     If that is the case, it will break logout. */
  appName = [[NSUserDefaults standardUserDefaults]
    objectForKey: @"GSWorkspaceApplication"];
#endif
  if (appName == nil)
    {
      // NOTE: appName is defined as SCSystemNamespace in EtoileSystem.h
      appName = @"/etoilesystem"; // @"EtoileWorkspaceServer";
    }

  return [self connectToApplication: appName launch: launchFlag];
}

@end
