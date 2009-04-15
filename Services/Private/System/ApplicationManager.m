/*
	ApplicationManager.m
 
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
// loaded, linking AppKit by default is bad, then put this stuff in a bundle 
// and load it only when necessary. Or may be put this stuff in another daemon.

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSInvocation+Etoile.h>
#import "ApplicationManager.h"
#import "EtoileSystem.h"
#include <sys/types.h>
#include <signal.h>
// FIXME: Not sure the following line is needed on some platforms or never?
//#import "OSType.h"

/* Strings with log out result description. They are used in informative alerts
   that give feedback to the user about his log out choice. */
static NSString *cancelReplyText = nil;
static NSString *noReplyText = nil;
static NSString *hasQuitReplyText = nil;

@interface NSWorkspace (gsprivate)
- (id) _connectApplication:(id) appName;
@end

@interface ApplicationManager (Private)
- (void) setUpTerminateLaterTimerWith: (NSString *)name;
- (void) checkTerminatingLaterApplicationWithName: (NSString *)appName;
- (void) checkTerminatingNowApplicationWithName: (NSString *)appName;
@end


@implementation ApplicationManager

static ApplicationManager *serverInstance = nil;
static NSConnection *serverConnection = nil;

/** Returns a proxy of ApplicationManager singleton in remote processes or the
    singleton object itself in the local process (etoile_system presently). */
+ (id) sharedInstance
{
	if (serverInstance == nil)
	{
		serverInstance = [self new];
		[ApplicationManager setUpServerInstance: serverInstance];
	}

	return serverInstance;
}

/** Assigns <param>instance</param> object as the singleton to be returned by
    -sharedInstance. Also creates a connection and vends 
    <param>instance</param> over it, that lets other processes access it
    through a proxy. */
+ (BOOL) setUpServerInstance: (id)instance
{
	ASSIGN(serverInstance, instance);

	/* Finish set up by exporting server instance through DO */
	NSConnection *theConnection = [NSConnection defaultConnection];

	[theConnection setRootObject: instance];
	if ([theConnection registerName: @"/etoileusersession"] == NO) 
	{
		// FIXME: Take in account errors here.
		NSLog(@"Unable to register the user session namespace %@ with DO", 
			@"/etoileusersession");

		return NO;
	}
	[theConnection setDelegate: self];

	ASSIGN(serverConnection, theConnection);
	
	NSDebugLLog(@"ApplicationManager", @"Setting up ApplicationManager server \
instance");
	
	return YES;
}

- (void) dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];

	TEST_RELEASE (launchedApplications);
	TEST_RELEASE (waitedApplications);
	TEST_RELEASE (terminateLaterTimers);
	TEST_RELEASE (replyLock);
	TEST_RELEASE (serverConnection);

	[super dealloc];
}

/** Returns a fully initialized ApplicationManager instance. */
- (id) init
{
	if ((self = [super init]) != nil)
	{
		NSNotificationCenter * nc;

		cancelReplyText = _(@"Service %@ cancels the log out.");
		noReplyText = _(@"Service %@ does not reply."); // You can continue the log out by choosing Force To Quit.
		hasQuitReplyText = _(@"Service %@ does not quit in the 1 minute delay \
        requested to let you save your documents or finish you activity.");

		launchedApplications = [NSMutableDictionary new];
		waitedApplications = [NSMutableDictionary new];
		terminateLaterTimers = [NSMutableArray new];
		replyLock = [NSLock new];

		nc = [[NSWorkspace sharedWorkspace] notificationCenter];
		[nc addObserver: self
		       selector: @selector(noteApplicationLaunched:)
		           name: NSWorkspaceDidLaunchApplicationNotification
		         object: nil];
		[nc addObserver: self
		       selector: @selector(noteApplicationTerminated:)
		           name: NSWorkspaceDidTerminateApplicationNotification
		         object: nil];

		NSInvocation *inv = [NSInvocation invocationWithTarget: self 
		                                              selector: @selector(checkLiveApplications)
		                                             arguments: nil];
		ASSIGN(autocheckTimer, [NSTimer scheduledTimerWithTimeInterval: 1.0
		                                                    invocation: inv
		                                                       repeats: YES]);
	}

	return self;
}

/** Returns a list of launched applications. The list is structured in the
    format as returned by -[NSWorkspace launchedApplications]. */
- (NSArray *) launchedApplications
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:
		[launchedApplications count]];
	NSEnumerator *e = [launchedApplications objectEnumerator];
	NSDictionary *entry = nil;
	NSArray *maskedApps = [[SCSystem serverInstance] maskedProcesses];

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

/** Returns a list of applications launched by the user, this excludes the ones
    launched by the system (known with -[SCSystem maskedProcesses]). The list 
    is a subset of the list returned by -launchedApplications. */
- (NSArray *) userApplications
{
	NSArray *maskedApps = [[SCSystem serverInstance] maskedProcesses];
	NSMutableArray *userApps = [[self launchedApplications] mutableCopy];

	[userApps removeObjectsInArray: maskedApps];
	NSDebugLLog(@"ApplicationManager", @"User applications: %@", userApps);

	return userApps;
}

/** Notification invoked when an NSWorkspaceDidLaunchApplicationNotification
    is received. */
- (void) noteApplicationLaunched: (NSNotification *)notif
{
	NSDictionary * appInfo = [notif userInfo];
	NSString * appName = [appInfo objectForKey: @"NSApplicationName"];

	if (appName != nil)
	{
		[launchedApplications setObject: appInfo forKey: appName];

		NSDebugLLog(@"ApplicationManager", @"App %@ launched", appName);
	}
}

/** <p>Notification invoked when an NSWorkspaceDidTerminateApplicationNotification
    is received.</p>
    <p>During a log out procedure, when no running user applications can be 
    found anymore and this method is called, it is in charge of handling the 
    last part of the log out procedure by calling back SCSystem with 
    -replyToLogOutOrPowerOff:. That happens on last user application 
    termination whose outcome is the previously mentioned notification.</p>*/
- (void) noteApplicationTerminated: (NSNotification *)notif
{
	NSDictionary *userInfo = [notif userInfo];
	NSString *appName = [userInfo objectForKey: @"NSApplicationName"];

	if ([launchedApplications objectForKey: appName] != nil)
    {
		[launchedApplications removeObjectForKey: appName];

		NSDebugLLog(@"ApplicationManager", @"App %@ terminated", appName);
	}

	if (logOut == NO)
		return;

	/* If we are in a log out procedure, we check the applications which 
		 terminated is not the last application to terminate we are waiting for. */
	int userAppCount = [[self userApplications] count];

	NSDebugLLog(@"ApplicationManager", @"Waiting %i user apps to terminate in launched apps: %@", userAppCount, launchedApplications);

	if (userAppCount == 0)
	{
		logOut = NO; /* Exiting log out procedure */

		// NOTE: The next line is important to have the 
		// -terminateAllApplicationsOnOperation: run loop exited.
		[terminateLaterTimers makeObjectsPerformSelector: @selector(invalidate)];
		[terminateLaterTimers removeAllObjects];
		[waitedApplications removeAllObjects];

		[[SCSystem serverInstance] performSelectorOnMainThread: 
			@selector(replyToLogOutOrPowerOff:) withObject: nil waitUntilDone: NO];
	}
}

/** <p>This method checks all applications returned by -launchedApplications are
    still running. For each application which exited since the last check, it
    posts NSWorkspaceDidTerminateApplicationNotification. Usually this should
    not arise unless application exist abruptly since they are in charge of 
    posting this notification themselves.</p>
    <p>Only works on Linux currently (more operating systems should be supported
    in future).</p> */
- (void) checkLiveApplications
{
	NSMutableArray *appsToRemove = [NSMutableArray array];
	NSEnumerator *e = [launchedApplications objectEnumerator];
	NSDictionary *entry = nil;

	/* Look for non-existing apps first (we can't remove them immediately,
	   because that would case the object enumerator to mess up) */
	while ((entry = [e nextObject]) != nil)
	{

#ifdef LINUX
		// NOTE: on Linux we use the /proc filesystem

		if (![[NSFileManager defaultManager] fileExistsAtPath:
			[@"/proc" stringByAppendingPathComponent: [[entry
			objectForKey: @"NSApplicationProcessIdentifier"] description]]])
		{
			[appsToRemove addObject: [entry objectForKey: 
				@"NSApplicationName"]];
		}
#endif

	}

	/* Now remove the non-existing apps */
	if ([appsToRemove count] > 0)
	{
		NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace]
			notificationCenter];
		NSEnumerator *e = [appsToRemove objectEnumerator];
		NSString *appName = nil;

		while ((appName = [e nextObject]) != nil)
		{
			NSDictionary *userInfo = [launchedApplications 
				objectForKey: appName];
			NSNotification *notif = [NSNotification
				notificationWithName: NSWorkspaceDidTerminateApplicationNotification
				object: self userInfo: userInfo];

			/* Synthetize a shutdown notification so that any app waiting for 
			   the shutdown app knows. However, first send the event to us, so 
			   that we update our list first. */
			[self noteApplicationTerminated: notif];
			[nc postNotification: notif];
		}
	}
}

/** <p>Terminates all running applications by contacting each and asking it to 
    terminate itself gracefully. The dialog established with applications 
    follows the session protocol. This method is used on log out or power off.
    </p>
    <p>Only applications returned by -userApplications are asked to terminate.
    The sessions protocol is made of <code>SCSession</code> protocol and an
    informal protocol part of NSApplication(Etoile).</p>
    <p>This method triggers an asynchronous reply.</p> */
- (void) terminateAllApplicationsOnOperation: (NSString *) operation
{
	/* If we are already in a log out procedure we discard any other log out
	   requests. This acts as a primitive lock that coalesces log out requests. */
	if(logOut)
		return;

	/* We set up a pool in case the method has been called in a thread */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *ommitedApps = [[SCSystem serverInstance] maskedProcesses];
	NSEnumerator *e = [launchedApplications objectEnumerator];
	NSDictionary *appEntry = nil;
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];

	NSDebugLLog(@"ApplicationManager", @"Trying to terminate all apps except: %@",
	ommitedApps);

	/* We clean old application proxy list to be sure it's really empty */
	[waitedApplications removeAllObjects];

	logOut = YES; /* Entering log out procedure */

	/* First case, no applications running */
	if ([[self userApplications] count] == 0)
	{
		[[SCSystem serverInstance] 
			performSelectorOnMainThread: @selector(replyToLogOutOrPowerOff:)
			                 withObject: nil 
		                  waitUntilDone: NO];
	}

	/* Second case, some applications running */
	while ((appEntry = [e nextObject]) != nil)
	{
		NSString *appName = [appEntry objectForKey: @"NSApplicationName"];
		NSApplicationTerminateReply reply = -1;
		id app = nil;

		/* Skip System tasks */
		if ([ommitedApps containsObject: appName])
			continue;

		// FIXME: -connectToApplication:launch: from WorkspaceCommKit doesn't work,
		// wrongly triggering an NSConnection method something like 
		// _services:forwardToProxy:. Therefore we use a private NSWorkspace method
		// for now.
		app = [workspace _connectApplication: appName];
		if (app == nil)
		{
			NSLog(_(@"WARNING! ApplicationManager cannot connect to application %@ at "
				@"log out, ignoring."), appName);

			  continue;
		}

		/* We retain the connection to the application by putting its proxy in 
		   a dictionary */
		[waitedApplications setObject: app forKey: appName];

		NS_DURING

			NSDebugLLog(@"ApplicationManager", @"Request \
-shouldTerminateOnOperation: to %@", appName);
			reply = [app shouldTerminateOnOperation: operation];

		NS_HANDLER

			// FIXME: Improve error reporting and recovering. We might kill the
			// bad process...
			//kill ([[appEntry objectForKey: @"NSApplicationProcessIdentifier"]
			//intValue], SIGKILL);
			NSLog(@"Error on -shouldTerminateOnOperation: to %@. %@", 
				appName, [localException reason]);
			reply = NSTerminateNow;
			continue;

		NS_ENDHANDLER

		/* If reply value is different from NSTerminateLater, just ignore it. 
		   For NSTerminateLater, we must set up the timer now rather than in 
		   -replyToTerminate:info: because before trying to reply the remote 
		   application can block in -terminateOnOperation:inSession: by asking
		   user feedback with UI panels (document reviewing is an example). 
		   After requesting delay an application can reply NSTerminateCancel or
		   NSTerminateNow too through -replyToTerminate:info:, that's why we 
		   always handle those replies in -replyToTerminate:info: method 
		   (rather than in the switch statement above). 
		   That works well because -terminateOnOperation:inSession: returns 
		   results consistent with -shouldTerminateOnOperation:. */
		switch (reply)
		{
			case NSTerminateLater:
				/* When an application returns such a reply, its termination 
				   will be checked in -checkTerminatingLaterApplicationWithName: */
				NSDebugLLog(@"ApplicationManager", @"%@ will terminate later", 
					appName); 

				[self performSelectorOnMainThread: @selector(setUpTerminateLaterTimerWith:) 
					withObject: appName waitUntilDone: YES];
				break;

			case NSTerminateCancel:
				NSDebugLLog(@"ApplicationManager", @"%@ will cancel terminate operation",
					appName); 
		  		break;

			case NSTerminateNow:
				NSDebugLLog(@"ApplicationManager", @"%@ will terminate immediately", 
					appName);
				break;
		}

		/* Applications will reply to -terminateOperation:inSession by calling 
		   back asynchronously -replyToTerminate:info: */
		[app terminateOnOperation: operation inSession: self];
	}

	[pool release];
}

/* This method must be run in the main thread.
   Facility method to create a timer bound to an application name. It is called
   to set up a delayed termination call when an application asks to terminate 
   later. */
- (void) setUpTerminateLaterTimerWith: (NSString *)name
{
	NSString *appName = [name copy];
	SEL selector = @selector(checkTerminatingLaterApplicationWithName:);
	NSInvocation *inv = [NSInvocation invocationWithTarget: self
	                                              selector: selector
	                                             arguments: A(appName)];

	/* Schedules a timer on the current run loop */
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval: 15.0 
	                                              invocation: inv
	                                                 repeats: NO];
	[terminateLaterTimers addObject: timer];
}

/* This is the method called by timers created in -setUpTerminaterLaterWith: 
   Any applications we connect to in this method have already requested a 
   delayed termination. Therefore we try again whether they accept to terminate
   now or not. If one of them doesn't accept: it replies NSTerminateLater or
   NSTerminateCancel, we cancel the log out. */
- (void) checkTerminatingLaterApplicationWithName: (NSString *)appName
{
	id app = [waitedApplications objectForKey: appName];
	int reply = -1;

	NSDebugLLog(@"ApplicationManager", @"Check terminating later application %@", 
		appName);

	if (app == nil)
	{
		NSLog(@"WARNING! App is nil in %@", waitedApplications);
		return;
	}

	// FIXME: We should check DO exceptions on such remote call.
	reply = [app shouldTerminateOnOperation: nil];
	NSDebugLLog(@"ApplicationManager", @"%@ terminating later replied %i", 
		appName, reply);

	/* We can close the connection to the application by releasing its proxy */
	[waitedApplications removeObjectForKey: appName];

	if (reply == NSTerminateNow)
	{
		/* Application must terminate by itself since we already issued a 
		   -terminateOnOperation:inSession: call (done in 
		   -terminateAllApplicationsOnOperation:. */
	}
	else if (reply == NSTerminateCancel || reply == NSTerminateLater)
	{
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: 
			appName, @"NSApplicationName", 
			[NSString stringWithFormat: noReplyText, appName], @"Reply", nil];

		logOut = NO; /* Exiting log out procedure */

		// NOTE: The next line is important to have the 
		// -terminateAllApplicationsOnOperation: run loop exited.
		[terminateLaterTimers makeObjectsPerformSelector: @selector(invalidate)];
		[terminateLaterTimers removeAllObjects];
		[waitedApplications removeAllObjects];

		[[SCSystem serverInstance] performSelectorOnMainThread: 
			@selector(replyToLogOutOrPowerOff:) withObject: info 
			waitUntilDone: NO];
	}
	else
	{
		NSLog(@"WARNING! Incorrect reply %d to -shouldTerminateOnOperation: by %@",
			reply, app);
	}
}

// FIXME: For safety we should implement...
- (void) checkTerminatingNowApplicationWithName: (NSString *)appName
{

}

// NOTE: It's important to declare info bycopy otherwise it will be referenced 
// in the distant application which could exit immediately after calling this 
// method. This means info would be a proxy with a dead connection, this can
// translate in bad side effects. 
/** <p>Handles reply sent by running application on log out request. If the
    application replies by <code>NSTerminateCancel</code> for <var>reply</var>
    parameter, the log ou cancellation is propagated back to SCSystem, 
    otherwise nothing happens. In the former case, -replyToLogOutOrPowerOff 
    gets called back with cancellation details in <var>info</var> dictionary 
    (the format is detailed in -[SCSystem replyToLogOutOrPowerOff:] 
    documentation).</p>
    <p>This method is called asynchronously by each application. It can be called 
    only if EtoileBehavior bundle is loaded in the application playing the 
    client role as described by the session protocol.</p>
    <p>If the application replies by <code>NSTerminateNow</code>, 
    ApplicationManager will wait to be notified of this termination before doing 
    anything. Such notification is processed by -noteApplicationTerminated:
    </p> */
- (oneway void) replyToTerminate: (int)reply info: (bycopy NSDictionary *)info
{
	[replyLock lock];

	NSMutableDictionary *newInfo = [info mutableCopy];
	NSString *replyText = nil;
	NSString *appName = [info objectForKey: @"NSApplicationName"];

	NSDebugLLog(@"ApplicationManager", 
		@"Application %@ replies to terminate: %i with info: %@", appName, reply, info);

	/* Log out may have been already cancelled probably because this 
	   application doesn't reply in time. In this case appName won't be present 
	   as a key anymore. See -checkTerminatingLaterApplicationWithName: */
	if ([[waitedApplications allKeys] containsObject: appName])
	{
		/* We can close the connection to the application by releasing its proxy */
		[waitedApplications removeObjectForKey: appName];
	
		switch (reply)
		{
			case NSTerminateCancel:
				logOut = NO; /* Exiting log out procedure */

				// NOTE: The next line is important to have the 
				// -terminateAllApplicationsOnOperation: run loop exited.
				[terminateLaterTimers makeObjectsPerformSelector: @selector(invalidate)];
				[terminateLaterTimers removeAllObjects];
				[waitedApplications removeAllObjects];

				replyText = [NSString stringWithFormat: cancelReplyText, appName];
				[newInfo setObject: replyText forKey: @"Reply"];
				[[SCSystem serverInstance] 
					performSelectorOnMainThread: @selector(replyToLogOutOrPowerOff:) 
					                 withObject: newInfo 
					              waitUntilDone: NO];
				break;
	
			case NSTerminateNow:
				// NOTE: As a safety check in case the application blocks during 
				// its exit, we should set up a timer that calls 
				// -checkTerminatingNowApplicationWithName in 20 seconds from now. 
				// If an applications doesn't quit in the elapsed time, we either ask 
				// the user whether he prefers to kill it or cancel the log out.
	
				/* If every applications have been gracefully terminated, we can log out or 
				   power off without worries. The last part of the procedure is handled is
				   -notedApplicationTerminated: */
				break;
		}
	}

	[replyLock unlock];
}

@end
