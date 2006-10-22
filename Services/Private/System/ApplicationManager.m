/*
	ApplicationManager.h
 
	ApplicationManager class allows to monitor usual user applications (based 
	on AppKit) to know which ones are running and be able to terminate them 
	properly on request (log out, power off etc.).
 
	Copyright (C) 2006 Saso Kiselkov
 
	Author:  Saso Kiselkov 
	         Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2006
 
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

// FIXME: When you take in account System can be use without any graphical UI 
// loaded, linking AppKit by default is bad,thne  put this stuff in a bundle 
// and load it only when necessary. Or may be put this stuff in another daemon.

#import "ApplicationManager.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <WorkspaceCommKit/NSWorkspace+Communication.h>

#import <sys/types.h>
#import <signal.h>

//#import "OSType.h"
#import "EtoileSystem.h"

@interface NSApplication (GracefulAppTermination)

- (BOOL) applicationShouldTerminateOnOperation: (NSString *) operation;
- (oneway void) reallyTerminateApplication;

@end

@implementation ApplicationManager

static ApplicationManager * shared = nil;

+ sharedInstance
{
  if (shared == nil)
    {
      shared = [self new];
    }

  return shared;
}

- (void) dealloc
{
  [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];

  TEST_RELEASE (launchedApplications);

  [super dealloc];
}

- init
{
  if ((self = [super init]) != nil)
    {
      NSNotificationCenter * nc;
      NSInvocation * inv;

      launchedApplications = [NSMutableDictionary new];

      nc = [[NSWorkspace sharedWorkspace] notificationCenter];
      [nc addObserver: self
             selector: @selector(noteApplicationLaunched:)
                 name: NSWorkspaceDidLaunchApplicationNotification
               object: nil];
      [nc addObserver: self
             selector: @selector(noteApplicationTerminated:)
                 name: NSWorkspaceDidTerminateApplicationNotification
               object: nil];

      inv = NS_MESSAGE(self, checkLiveApplications);
      ASSIGN(autocheckTimer, [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                          invocation: inv
                                                             repeats: YES]);
    }

  return self;
}

/**
 * Returns a list of launched applications. The list is structured in the
 * format as returned by -[NSWorkspace launchedApplications]
 */
- (NSArray *) launchedApplications
{
  NSMutableArray * array = [NSMutableArray arrayWithCapacity:
    [launchedApplications count]];
  NSEnumerator * e = [launchedApplications objectEnumerator];
  NSDictionary * entry;
  NSArray * maskedApps = [[SCSystem serverInstance] maskedProcesses];

  while ((entry = [e nextObject]) != nil)
    {
      NSString * appName = [entry objectForKey: @"NSApplicationName"];

      if (![maskedApps containsObject: appName] &&
          ![appName isEqualToString: EtoileSystemServerName])
        {
          [array addObject: entry];
        }
    }

  NSDebugLLog(@"ApplicationManager", @"Launched applications list queried, "
    @"returning: %@", array);

  return [[array copy] autorelease];
}

// notification invoked when an NSWorkspaceDidLaunchApplicationNotification
// is received
- (void) noteApplicationLaunched: (NSNotification *) notif
{
  NSDictionary * appInfo = [notif userInfo];
  NSString * appName = [appInfo objectForKey: @"NSApplicationName"];

  if (appName != nil)
    {
      [launchedApplications setObject: appInfo forKey: appName];

      NSDebugLLog(@"ApplicationManager", @"App %@ launched", appName);
    }
}

// notification invoked when an NSWorkspaceDidTerminateApplicationNotification
// is received.
- (void) noteApplicationTerminated: (NSNotification *) notif
{
  NSDictionary * userInfo = [notif userInfo];
  NSString * appName = [userInfo objectForKey: @"NSApplicationName"];

  if ([launchedApplications objectForKey: appName] != nil)
    {
      [launchedApplications removeObjectForKey: appName];

      NSDebugLLog(@"ApplicationManager", @"App %@ terminated", appName);
    }
}

- (void) checkLiveApplications
{
  NSEnumerator * e;
  NSDictionary * entry;
  NSMutableArray * appsToRemove = [NSMutableArray array];

  // look for non-existing apps first (we can't remove them immediatelly,
  // because that would case the object enumerator to mess up)
  e = [launchedApplications objectEnumerator];
  while ((entry = [e nextObject]) != nil)
    {
#ifdef LINUX
      // on Linux we use the /proc filesystem

      if (![[NSFileManager defaultManager] fileExistsAtPath:
        [@"/proc" stringByAppendingPathComponent: [[entry
        objectForKey: @"NSApplicationProcessIdentifier"] description]]])
        {
          [appsToRemove addObject: [entry objectForKey:
            @"NSApplicationName"]];
        }
#endif
    }

  // now remove the non-existing apps
  if ([appsToRemove count] > 0)
    {
      NSNotificationCenter * nc = [[NSWorkspace sharedWorkspace]
        notificationCenter];
      NSEnumerator * e = [appsToRemove objectEnumerator];
      NSString * appName;

      while ((appName = [e nextObject]) != nil)
        {
          NSDictionary * userInfo = [launchedApplications objectForKey: appName];
          NSNotification * notif = [NSNotification
            notificationWithName: NSWorkspaceDidTerminateApplicationNotification
                          object: self
                        userInfo: userInfo];

          // Synthetize a shutdown notification so that any app waiting
          // for the shutdown app knows. However, first send the event
          // to us, so that we update our list first.
          [self noteApplicationTerminated: notif];
          [nc postNotification: notif];
        }
    }
}

/**
 * Terminates all running applications by contacting each and
 * asking it to terminate itself gracefully. This method is used
 * when powering the workspace off.
 *
 * Only non-hidden apps (non-workspace processes) are terminated.
 *
 * @return YES if the workspace can power off, NO if it can't (some
 * application requested to stop the poweroff operation).
 */
- (BOOL) gracefullyTerminateAllApplicationsOnOperation: (NSString *) operation
{
  NSArray * ommitedApps = [[SCSystem serverInstance] maskedProcesses];
  NSEnumerator * e = [launchedApplications objectEnumerator];
  NSDictionary * appEntry;
  NSWorkspace * ws = [NSWorkspace sharedWorkspace];

  while ((appEntry = [e nextObject]) != nil)
    {
      NSString * appName = [appEntry objectForKey: @"NSApplicationName"];
      NSApplicationTerminateReply reply;
      id app;

      // skip workspace process apps
      if ([ommitedApps containsObject: appName])
        {
          continue;
        }
	// FIXME: -connectToApplication:launch: from WorkspaceCommKit doesn't work,
	// wrongly triggering an NSConnection method something like 
	// _services:forwardToProxy:. Therefore we use a private NSWorkspace method
	// for now.
      app = [ws _connectApplication: appName];
      if (app == nil)
        {
          NSLog(_(@"Warning: couldn't connect to application %@ at "
                  @"log out, ignoring."), appName);

          continue;
        }

      NS_DURING
        NSLog(@"TTT Sending -applicationShouldTerminateOnOperation: to app: %@",
          appName);
        reply = [app applicationShouldTerminateOnOperation: operation];
        NSLog(@"TTT app %@ replied %i", appName, reply);
      NS_HANDLER
        NSLog(_(@"Error gracefully terminating application %@: %@. "
                @"I'm killing it."), appName, [localException reason]);
        kill ([[appEntry objectForKey: @"NSApplicationProcessIdentifier"]
          intValue], SIGKILL);

        continue;
      NS_ENDHANDLER

      switch (reply)
        {
          // TODO - implement NSTerminateLater
        case NSTerminateLater:
        case NSTerminateCancel:
          NSLog(@"TTT cancelling operation");
          return NO;
        case NSTerminateNow:
          NSLog(@"TTT proceeding with shut down of app %@", appName);
          [app reallyTerminateApplication];
          NSLog(@"TTT app %@ shut down", appName);
          break;
        }
    }

  return YES;
}

@end
