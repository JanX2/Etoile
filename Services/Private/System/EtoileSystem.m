/*
    EtoileSystem.m
 
    Etoile main system process, playing the role of both init process and main 
    server process. It takes care to start, stop and monitor Etoile core 
    processes, possibly restarting them when they die.
 
    Copyright (C) 2006 Quentin Mathe
 
    Author:  Quentin Mathe <qmathe@club-internet.fr>
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

#import "EtoileSystem.h"
#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>
#endif
#import "NSArrayAdditions.h"
#import "ApplicationManager.h"
#import "SCTask.h"

// FIXME: When you take in account System can be use without any graphical UI 
// loaded, linking AppKit by default is bad,thne  put this stuff in a bundle 
// and load it only when necessary. Or may be put this stuff in another daemon.
// In the present case, we use it to display alert panels, in fact that should
// be handled with a separate UI server (aka systemUIServer)
#import <AppKit/AppKit.h>

/* The current domain scheme '/etoilesystem/tool' and '/etoilesystem/application'
   is work ins progress and doesn't reflect the final scheme to be used when 
   CoreObject will be ready. */

/** Main System Process List
    
    name                        owner
    
    etoile_system               root
    etoile_objectServer         root or user
    
    etoile_userSession          user
    etoile_projectSession       user
    
    etoile_windowServer         root
    Azalea                      root or user
    etoile_menuServer           user
    
    etoile_identityUI           user
    etoile_securityUIServer     user
    etoile_systemUIServer       user 
  */


static id serverInstance = nil;
static NSConnection *serverConnection = nil;
static id proxyInstance = nil;
static NSString *SCSystemNamespace = nil;

NSString *SCNoneOperation = @"SCNoneOperation";
NSString *SCLogOutOperation = @"SCLogOutOperation";
NSString *SCShutDownOperation = @"SCShutDownOperation";
NSString *SCRebootOperation = @"SCRebootOperation";

NSString * const EtoileSystemServerName = @"etoile_system";

/* NSError related extensions */

NSString * const EtoileSystemErrorDomain =
  @"EtoileSystemErrorDomain";
const int EtoileSystemTaskLaunchingError = 1;

/**
 * A shorthand function for setting NSError pointers.
 *
 * This function sets a non-NULL error pointer to an NSError
 * instance created from it's arguments. The error's error domain
 * is always set to WorkspaceProcessManagerErrorDomain.
 *
 * @param error The pointer which, if not set to NULL, will be
 *      filled with the error description.
 * @param code The error code which to set in the NSError instance.
 * @param reasonFormat A format string describing the reason for
 *      the error. Following it is a variable number of arguments,
 *      all of which are arguments to this format string.
 */
static void 
SetNonNullError (NSError ** error, int code, NSString * reasonFormat, ...)
{
	if (error != NULL)
	{
		NSDictionary * userInfo;
		NSString * reason;
		va_list arglist;

		va_start (arglist, reasonFormat);
		reason = [NSString stringWithFormat: reasonFormat arguments: arglist];
		va_end (arglist);

		userInfo = [NSDictionary
			dictionaryWithObject: reason forKey: NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain: EtoileSystemErrorDomain
		                             code: code
		                         userInfo: userInfo];
	}
}

/* Private SCHardware interface */

BOOL SCHardwareIsShutDownSupported();
BOOL SCHardwareIsRebootSupported();
BOOL SCHardwareShutDown();
BOOL SCHardwareReboot();
BOOL SCHardwareSuspend();

@interface SCSystem (Private)
- (id) initWithArguments: (NSArray *)args;

/* Notifications */
- (void) noteApplicationLaunched: (NSNotification *) notif;

/* Launch Queue methods */
- (NSMutableArray *) processQueueWithProcesses: (NSDictionary *)processes;
- (NSMutableArray *) processGroupQueueWithProcessQueue: (NSArray *)processQueue;
- (void) startProcessesSequentiallyByPriorityOrder: 
	(NSMutableArray *)launchQueue;
- (void) startProcessesParallely: (NSArray *)processGroup;

- (void) terminateSession;
- (void) reportPowerOffError: (NSString *)op;
@end

@interface SCSystem (HelperMethodsPrivate)
- (void) checkConfigFileUpdate;
- (void) findConfigFileAndStartUpdateMonitoring;
- (void) synchronizeProcessesWithConfigFile;

- (void) startProcessWithUserFeedbackForDomain: (NSString *)domain;
@end


/*
 * Main class SCSystem implementation
 */

/**
 * Instances of this class manage Etoile system processes. A system
 * process is a process (either an application or a plain UNIX command)
 * which are to be re-run every time they finish. Therefore it is possible
 * to e.g. kill the menu server and this object will restart it again
 * automatically, thus forcing a reload of the menu server's menulets.
 */
@implementation SCSystem

+ (void) initialize
{
	if (self == [SCSystem class])
	{
		// FIXME: For now, that's a dummy namespace.
		SCSystemNamespace = @"/etoilesystem";
	}
}

/* Returns SCSystem singleton. You should use this method to access SCSystem 
   inside etoile_system process. */
+ (id) serverInstance
{
	return serverInstance;
}

/* Set up SCSystem singleton by registering it into DO. This makes possible to 
   have it returned as a proxy by -sharedInstance in remote applications. */
+ (BOOL) setUpServerInstance: (id)instance
{
	ASSIGN(serverInstance, instance);

	/* Finish set up by exporting server instance through DO */
	serverConnection = [[NSConnection alloc] 
		initWithReceivePort: [NSPort port] sendPort: [NSPort port]];
	
	[serverConnection setRootObject: instance];
	if ([serverConnection registerName: SCSystemNamespace] == NO) 
	{
		// FIXME: Take in account errors here.
		NSLog(@"Unable to register the system namespace %@ with DO", 
			SCSystemNamespace);

		return NO;
	}
	[serverConnection setDelegate: self];
	
	NSLog(@"Setting up SCSystem server instance");
	
	return YES;
}

/** Returns SCSystem proxy that can be used to interact with Etoile main daemon
    It should only be used on client side. */
/* It's mandatory to have call -setUpServerInstance: before usually in the 
   server process itself. */
+ (SCSystem *) sharedInstance
{
	proxyInstance = [NSConnection 
		rootProxyForConnectionWithRegisteredName: SCSystemNamespace
		host: nil];

	// FIXME: Use Runtime introspection to create the proxy protocol on the fly.
	//[proxyInstance setProtocolForProxy: @protocol(blabla)];

	/* We probably don't need to release it, it's just a singleton. */
	return RETAIN(proxyInstance); 
}

- (id) init
{
    return [self initWithArguments: nil];
}

/* Designated initializer */
- (id) initWithArguments: (NSArray *)args
{
	if ((self = [super init]) != nil)
	{
		_processes = [[NSMutableDictionary alloc] initWithCapacity: 20];
		_launchQueue = [[NSMutableArray alloc] initWithCapacity: 20];
		//_launchGroup = [[NSMutableArray alloc] initWithCapacity: 20];

		return self;
	}
	
	return nil;
}

- (void) dealloc
{
	DESTROY(_processes);
	DESTROY(_launchQueue);

	TEST_RELEASE(monitoringTimer);
	TEST_RELEASE(configFilePath);
	TEST_RELEASE(modificationDate);
	
	[super dealloc];
}

/** First creates ApplicationManager instance, then starts NSApplication-based
    run loop used by SCSystem at this point. */
- (void) run
{
	/* We trigger the ApplicationManager singleton creation in order it 
	   starts to monitor user applications. The return value is ignored. */
	[ApplicationManager sharedInstance];
	/* We trigger the NSApplication singleton creation in order we can use
	   UI stuff like window, panel etc. The return value is ignored. */
	[[NSApplication sharedApplication] setDelegate: self];
	[[NSApplication sharedApplication] run];
}

/* Only called by SCTask. */
- (void) noteApplicationLaunched: (NSNotification *)notif
{
	if (_launchQueueScheduled == NO)
	{
		NSLog(@"WARNING: Received launch notification %@ without a launch "
			  @"queue scheduled", notif);
		return;
	}

	/* Discard launch notifications System itself and third-party processes 
	   that get indirectly launched or are already running, otherwise the launch 
	   queue will be messed up. */
	BOOL isLaunchQueueRelated = ([[notif object] isKindOfClass: [SCTask class]] == NO);
	if (isLaunchQueueRelated)
		return;

	SCTask *launchedProcess = [notif object];
	NSString *processName = [[notif userInfo] objectForKey: @"NSApplicationName"];

	NSDebugLLog(@"SCSystem", @"Remove %@ in launch queue", launchedProcess);
	[_launchGroup removeObject: launchedProcess];
	NSDebugLLog(@"SCSystem", @"Process group count is now %d", [_launchGroup count]);

	BOOL processGroupLaunchFinished = [_launchGroup count] == 0;
	if (processGroupLaunchFinished)
	{
		NSDebugLLog(@"SCSystem", @"Going to reenter startProcessSequentiallyByPriorityOrder...");
		[self startProcessesSequentiallyByPriorityOrder: nil];
	}
}

- (void) applicationDidFinishLaunching: (NSNotification *)not
{
	NSDebugLLog(@"SCSystem", @"Did finish launching");
	//NSRunAlertPanel(_(@"Test Alert Panel"), nil, nil, nil, nil);
	NSMutableArray *processQueue = nil;
	NSMutableArray *launchQueue = nil;

	_launchQueueScheduled = YES;

	/* Find task list config file and synchronize _processes data structure 
	   with it */ 
	[self findConfigFileAndStartUpdateMonitoring];
	if (configFilePath != nil)
	{
		/* We register the core processes */
		// FIXME: Takes care to standardize Etoile core processes naming scheme.
		[self synchronizeProcessesWithConfigFile];
	}

	/* We need to register for application launching finished notifications
	   just to to be able to launch applications sequentially. */
	[[[NSWorkspace sharedWorkspace] notificationCenter] 
		addObserver: self
		   selector: @selector(noteApplicationLaunched:)
		       name: NSWorkspaceDidLaunchApplicationNotification
		     object: nil];

	/* Now we can launch tasks registered in _processes data structure. First 
		we convert it into a launch queue to take in account launch priority 
	    order. */
	processQueue = [self processQueueWithProcesses: _processes];
	launchQueue = [self processGroupQueueWithProcessQueue: processQueue];
	[self startProcessesSequentiallyByPriorityOrder: launchQueue];
}

/*
 * Launch queue related code (launch by priority support)
 */ 

/** Returns a process launch queue by sorting processes values based on their
    launch priority. The queue is ordered by ascending priority number values. */
- (NSMutableArray *) processQueueWithProcesses: (NSDictionary *)processes
{
	NSSortDescriptor *desc = AUTORELEASE([[NSSortDescriptor alloc] 
		initWithKey: @"launchPriority" ascending: YES]);

	return [NSMutableArray arrayWithArray: [[_processes allValues] 
		   sortedArrayUsingDescriptors: [NSArray arrayWithObject: desc]]];
}

/** Returns a structured process launch queue where processes are grouped by 
	sets of identical launch priority. The queue is ordered by ascending priority number values. */
- (NSMutableArray *) processGroupQueueWithProcessQueue: (NSArray *)processQueue
{
	NSMutableArray *processGroupQueue = [NSMutableArray array]; /* List of process group ordered by ascending launch priority */
	NSMutableArray *processGroup = nil; /* Subset of all processes bound by the same launch priority */
	NSEnumerator *e = [processQueue objectEnumerator];
	SCTask *process = nil;

	/* Split processes inside processLaunchQueue */
	while ((process = [e nextObject]) != nil)
	{
		if (processGroup == nil || 
			([processGroup count] > 0 && 
			[[processGroup lastObject] launchPriority] < [process launchPriority]))
		{
			processGroup = [NSMutableArray array];
			[processGroupQueue addObject: processGroup];

			NSDebugLLog(@"SCSystem", @"Added process %@ to process group %@ from \
				process queue %@", process, processGroup, processQueue);
		}
		[processGroup addObject: process];
	}

	return processGroupQueue;	
}

- (void) startProcessesSequentiallyByPriorityOrder: (NSMutableArray *)launchQueue
{
	if (launchQueue != nil 
		&& [launchQueue isEqual: _launchQueue] == NO)
	{
		ASSIGN(_launchQueue, launchQueue);
	}

	NSDebugLLog(@"SCSystem", @"Start processes by priority with launch \
        queue %@", _launchQueue);

	if ([_launchQueue count] > 0)
	{
		NSArray *processGroup = RETAIN([_launchQueue objectAtIndex: 0]);
		[_launchQueue removeObject: processGroup];

		NSDebugLLog(@"SCSystem", @"Process group count is %d, process launch \
            queue count is %d", [processGroup count], [_launchQueue count]);

		[self startProcessesParallely: processGroup];
		RELEASE(processGroup);
	}
	else /* The launch queue is empty now */
	{
		NSLog(@"Launch queue is empty now");
		_launchQueueScheduled = NO;
		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];
	}
}

- (void) startProcessesParallely: (NSArray *)processGroup
{
	NSDictionary *domains = [NSDictionary dictionaryWithObjects: 
		[_processes allKeys] forKeys: [_processes allValues]];
	NSEnumerator *e = [processGroup objectEnumerator];
	SCTask *process = nil;
	BOOL hasLaunchedProcess = NO;

	DESTROY(_launchGroup);
	_launchGroup = [processGroup mutableCopy];

	NSDebugLLog(@"SCSystem", @"Launch a process group in parallel: %@", 
		_launchGroup);

	while ((process = [e nextObject]) != nil)
	{
		NSDebugLLog(@"SCSystem", @"Check whether to start process %@ with \
			launchOnStart %d and launchPriority %d", process, 
			[process launchOnStart], [process launchPriority]);

		if ([process launchOnStart])
		{
			NSString *domain = [domains objectForKey: process];

			hasLaunchedProcess = YES;
			[self startProcessWithDomain: domain error: NULL]; //FIXME: Handles error
		}
		else
		{
			/* If the process isn't launched, it won't be removed from 
			   _launchGroup by -noteApplicationLaunched:, therefore we must
			   remove it now to prevent any blocking of the launch queue. */
			[_launchGroup removeObject: process];
		}
	}

	/* When no processes has been launched in the actual group, 
	   -noteApplicationLaunched: won't called at all... which means we have to 
	   handle reentering -startProcessesSequentiallyByPriorityOrder: by ourself
	   in case the launch queue isn't yet empty. */
	if (hasLaunchedProcess == NO)
	{
		NSDebugLLog(@"SCSystem", @"No processes launched for group %@",
			processGroup);
		NSDebugLLog(@"SCSystem", @"Going to reenter \
            startProcessSequentiallyByPriorityOrder...");
			[self startProcessesSequentiallyByPriorityOrder: nil];
	}
}

/** <p>Launchs process identified by <var>domain</domain>.</p>
    <p>Note this method has no effect if you call it on a suspended process.
    </p>
    <deflist>
    <term>domain</term><desc>A path which the process has been bound to. Note
    that a process might be bind to more than one domain, though this should
    not happen. In a similar way, an executable might be referenced and used by 
    several processes. Hence SCSystem does not prevent to launch an already
    running executable through itself or in another manner.</desc>
    <term>error</term><desc>A pointer to an NSError variable which will be 
    filled with an NSError instance in case of a launch error.</desc>
    </deflist>
    <p>Returns YES if the launch succeeds, NO if it doesn't and indicates the
    reason in <var>error</var> argument.</p> */
- (BOOL) startProcessWithDomain: (NSString *)domain error: (NSError **)error
{
	SCTask *process = [_processes objectForKey: domain];

	/* May be we should check whether an already running process with the same 
       domain exists...
	   Well, I'm not sure we should do this, but it could be nice, we would 
	   have to identify the process in one way or another (partially not to
	   compromise the security). */

	if (process == nil)
	{
		// FIXME: Set up an error explaing no process has been bound to this
		// domain.
		return NO;
	}

	NSDebugLLog(@"SCSystem", @"Try to start process %@ associated with domain %@", 
		[process path], domain);
		
    if ([process isRunning])
	{
		// FIXME: Set up an error explaing a process is already running for
		//  this domain.
		return NO;
	}
	else if ([process isStopped])
	{
		NSDebugLLog(@"SCSystem", @"Will try to restart this process that already exited");
		
		/* We create a fresh task instance since we cannot run a task more than
		  one time. */
		process = [SCTask taskWithTask: process];;
		[_processes setObject: process forKey: domain];
	}

	NS_DURING
		/* We don't relaunch any processes that already failed to launch three 
		   times */
		if ([process launchFailureCount] < 3)
			[process launchForDomain: domain];
    NS_HANDLER
			SetNonNullError (error, EtoileSystemTaskLaunchingError,
				_(@"Error launching program at %@: %@"), [process path],
				[localException reason]);

			return NO;
	NS_ENDHANDLER

	[[NSNotificationCenter defaultCenter] 
		addObserver: self
		   selector: @selector(processTerminated:) 
		       name: NSTaskDidTerminateNotification
		     object: process];

	return YES;
}

/** <p>Restarts process identified by <var>domain</var> which was suspended 
    previously with -suspendProcessWithDomain:error:. Doesn't do anything if
    you call it on a process which hasn't been suspended first.</p>
    <p>This method should make any suspended processes reactive UI level if 
    they have one.</p>
    <p>Works by sending POSIX signal SIGCONT behind the scene. You should 
    signal suspended processes with SIGCONT directly.</p>
    <p>Note that calling this method on a stopped process has no effect.</p>
    <p>Returns YES if the restart succeeds, NO if it doesn't and indicates the
    reason in <var>error</var> argument.</p> */
- (BOOL) restartProcessWithDomain: (NSString *)domain error: (NSError **)error
{
	BOOL stopped = NO;
	BOOL restarted = NO;

	stopped = [self stopProcessWithDomain: domain error: NULL];

	/* The process has been properly stopped or was already, then we restart it 
	   now. */
	if (stopped)
		restarted = [self restartProcessWithDomain: domain error: NULL];

	return restarted;
}

/** <p>Terminates process identified by <var>domain</var>.</p>
    <p>When the process is an AppKit-based application, the application is 
    stopped by sending -terminate message. If it does not exits after a five
    seconds delay it, the termination occurs by signaling it with SIGKILL. For
    other processes, SIGQUIT is sent before falling back on SIGKILL.</p>
    <p>Returns YES if the stop succeeds, NO if it doesn't and indicates the
    reason in <var>error</var> argument.</p> */
- (BOOL) stopProcessWithDomain: (NSString *)domain error: (NSError **)error
{
	NSTask *process = [_processes objectForKey: domain];

	NSDebugLLog(@"SCSystem", @"Trying to terminate process %@ with domain %@", 
		[process launchPath], domain);

    if ([process isRunning])
    {
		NSDebugLLog(@"SCSystem", @"Terminate process now");

		NS_DURING
			[process terminate];
    	NS_HANDLER
			NSLog(@"Failed to terminate process %@ with domain %@", 
				[process launchPath], domain);
			/* SetNonNullError (error, EtoileSystemTaskTerminatingError,
				 _(@"Error terminating program at %@: %@"), [process path],
					[localException reason]); */
		NS_ENDHANDLER
		
		/* Now check termination status. If the process is still alive, we kill it. */

        /* We check the process has been really terminated before saying so. */
        if ([process isRunning] == NO)
		{
			// FIXME: Set up a timer to check whether the task has terminated 
			// in 5 seconds from now. Well could be better to thread this object
			// and make such method reentrant.
			NSLog(@"Process %@ still running...", process);
            return YES;
		}
    }

    return NO;
}

/** <p>Suspends process identified by <var>domain</var>. Any suspended 
    processes will appear frozen at UI level if they have one, in all cases 
    they won't reply to any events.</p>
    <p>Finally they will only resume if you call 
    -restartProcessWithDomain:error: or if you send them POSIX signals like 
    SIGCONT. Note that you should not signal a process with SIGCONT to resume, 
    but rather uses -restartProcessWithDomain:error: otherwise SCSystem will 
    still consider the process as suspended.</p>
    </p>Works by sending SIGSTOP signal behind the scene. If you signal a 
    process with SIGSTOP directly, SCSystem would still consider it as 
    running.</p>
    <p>Returns YES if the suspend succeeds, NO if it doesn't and indicates the
    reason in <var>error</var> argument.</p> */
- (BOOL) suspendProcessWithDomain: (NSString *)domain error: (NSError **)error
{
	NSTask *process = [_processes objectForKey: domain];

	if ([process isRunning])
	{
		return [process suspend];
	}
	
	return NO;
}

/** <p>Synchronizes processes returned by -processes which SCSystem is in 
    charge of with the config list <file>SystemTaskList.plist</file>. The 
    config list file describes processes which must be launched in precise 
    circumstances and ways to have a working Etoile environment.</p>
    <p>This method is automatically called every two seconds by default.</p> */
- (void) loadConfigList
{
	[self checkConfigFileUpdate];
}

/** <p>Synchronizes the config list <file>SystemTaskList.plist</file> with the
    processes returned by -processes method. Uses this method with care since 
    it will overwrite the inital settings of <file>SystemTaskList</file>.
    Etoile environment may then not start properly on next login. It is mostly
    reserved to Etoile internal use.</p>
    <p><strong>Not implemented</strong></p> */
- (void) saveConfigList
{
	// TODO: Write the code to sync the _processes ivar and the config file
}

/** <p>Returns a list of Etoile system processes invisible to the user.</p>
    <p>This list is used by the application manager to determine which 
    applications it should ommit from its output and from terminating when
    shutting down gracefully.</p>
    <p>Returns an array of process names of processes to be kept masked.</p> */
- (NSArray *) maskedProcesses
{
	NSMutableArray *array = 
		[NSMutableArray arrayWithCapacity: [_processes count]];
	NSEnumerator *e = [_processes objectEnumerator];
	SCTask *processesEntry;

	/* Don't forget to add myself else ApplicationManager will kill us on log 
	   out or shut down. */
	[array addObject: @"etoile_system"];

	while ((processesEntry = [e nextObject]) != nil)
	{
		if ([processesEntry isHidden])
		{
			// NOTE: we could a Name key to the Task config file schema rather
			// than always extracting the name from the task/executable path.
			[array addObject: [processesEntry name]];
		}
	}
	
	return [[array copy] autorelease];
}

/** <p>Gracefully terminates all Etoile system processes at log out or power
    off time.</p>
    <p>Returns YES if the log out/power off operation can proceed, NO if an 
    app requested the operation to be halted.</p> */
- (BOOL) terminateAllProcessesOnOperation: (NSString *)op
{
	NSEnumerator *e = [[_processes allKeys] objectEnumerator];
	NSString *domain = nil;
	BOOL stoppedAll = NO;
	
	while ((domain = [e nextObject]) != nil)
	{
		stoppedAll = [self stopProcessWithDomain: domain error: NULL];
	}
	
  return stoppedAll;
}

/** Delays any log out, shut down or reboot operations underway by 
    <var>delay</var> value expressed in milliseconds. 
    <p><strong>Not implemented</strong></p> */
- (void) extendPowerOffBy: (int)delay
{
	NSLog(@"-extendPowerOffBy: not implemented");
}

/* Log out implementation called by both  -logOut and -powerOff: */
- (void) terminateSession
{
	/* Ask to close all applications gracefully and wait for a asynchronous 
       reply to be handled in -replyToLogOutOrPowerOff: */
	[[ApplicationManager sharedInstance] terminateAllApplicationsOnOperation: _operation];
}

/** Triggers log out operation. It asks ApplicationManager to terminate all 
    applications for the requested operation. Then SCSystem will wait 
    ApplicationManager reply through -replyToLogOutOrPowerOff: before doing 
    anything. If no applications has cancelled the log out, SCSystem exits. */
- (oneway void) logOut
{
	NSDebugLLog(@"SCSystem", @"Log out requested");

	if (_operation != nil)
	{
		NSLog(@"System cannot log out now. SCSystem is carrying on %@", _operation);
		return;
	}
	else
	{
		_operation = SCLogOutOperation;

		[self terminateSession];
	}
}

/** <p>Shuts down or reboots the computer depending on <var>reboot</var> flag 
    value. Initially triggers lot out.</p>
    <p>Read -logOut documentation to know more about it.</p> */
- (oneway void) powerOff: (BOOL)reboot
{
	NSDebugLLog(@"SCSystem", @"Power off requested");

	if (_operation != nil)
	{
		NSLog(@"System cannot power off now. SCSystem is carrying on %@", _operation);
		return;
	}

	if (reboot)
	{
		if (SCHardwareIsRebootSupported())
		{
			_operation = SCRebootOperation;
			[self terminateSession];
		}
		else
		{
			[self reportPowerOffError: SCRebootOperation];
		}
	}
	else
	{
		if (SCHardwareIsShutDownSupported())
		{
			_operation = SCShutDownOperation;
			[self terminateSession];
		}
		else
		{
			[self reportPowerOffError: SCShutDownOperation];
		}
	}
}

- (void) reportPowerOffError: (NSString *)op
{
	if ([op isEqual: SCShutDownOperation])
	{
		NSRunAlertPanel(_(@"The computer cannot be shutdown."),
			_(@"This limitation may occur either because you aren't allowed to shutdown or your configuration doesn't support shutdown properly."), nil, nil, nil);
	}
	else if ([op isEqual: SCRebootOperation])
	{
		NSRunAlertPanel(_(@"The computer cannot be reboot."), 
			_(@"This limitation may occur either because you aren't allowed to reboot or your configuration doesn't support reboot properly."), nil, nil, nil);
	}
}

/** Puts the computer into sleep mode until the user awake it through mouse or 
    keyboard events. */
- (oneway void) suspend
{
	NSDebugLLog(@"SCSystem", @"Suspend requested");

	if (_operation != nil)
	{
		NSLog(@"System cannot suspend now. SCSystem is carrying on %@", _operation);
	}
	else
	{
		if (SCHardwareSuspend() == NO)
		{
			NSRunAlertPanel(_(@"The computer cannot be put in sleep mode."), 
				_(@"This limitation may occur either because you aren't allowed to put it in sleep mode or your configuration doesn't support sleep mode properly."), nil, nil, nil);
		}
	}
}

/** Method called by ApplicationManager when this latter class has finished to
    to handle the log out work it is in charge of (usually application
    termination). Two replies can be passed:
    <enum>
    <item>Ready to log out (or power off)</item>
    <item>Log out cancelled by an application</item>
    </enum> */
- (void) replyToLogOutOrPowerOff: (NSDictionary *)info
{
	NSString *appName = [info objectForKey: @"NSApplicationName"];
	NSString *replyText = [info objectForKey: @"Reply"];

	NSDebugLLog(@"SCSystem", @"Log out reply info: %@", info);

	if (appName == nil)
	{
		/* All applications have been terminated, time to terminate our own 
           tasks. */
		BOOL readyToEnd = [self terminateAllProcessesOnOperation: _operation];

		if (readyToEnd == NO)
		{
			// TODO: handle the possibility that some processes fail to 
			// terminate
		}

		if ([_operation isEqual: SCShutDownOperation])
		{
			if (SCHardwareShutDown() == NO)
				NSLog(@"System fails to trigger shut down before logging out");
		}
		else if ([_operation isEqual: SCRebootOperation])
		{
			if (SCHardwareReboot() == NO)
				NSLog(@"System fails to trigger reboot before logging out");
		}

		/* Time to put an end to our own life */
		exit(0);
	}
	else
	{
		NSRunAlertPanel(_(@"Log out, shut down or reboot has been cancelled."),
			replyText, nil, nil, nil);

		/* Ready to accept new operation */
		_operation = nil;
	}
}

@end

/*
 * Helper methods for handling process list and monitoring their config files
 */

@implementation SCSystem (HelperMethodsPrivate)

/** <p>Launches a workspace process. This method is special in that if 
   launching the process fails, it queries the user whether to log out (fatal 
   failure), retry launching it or ignore it.</p>
   <p><deflist>
   <term>processDescription</term><desc>A description dictionary of the process
   which to launch.</desc>
   </deflist></p> */
- (void) startProcessWithUserFeedbackForDomain: (NSString *)domain
{
	NSError *error;
	
	relaunchProcess:
	if (![self startProcessWithDomain: domain error: &error])
	{
		int result;
	
		result = NSRunAlertPanel(_(@"Failed to launch the process"),
			_(@"Failed to launch the process \"%@\"\n"
			@"Reason: %@.\n"),
			_(@"Log Out"), _(@"Retry"), _(@"Ignore"),
			[[_processes objectForKey: domain] path],
			[[error userInfo] objectForKey: NSLocalizedDescriptionKey]);
	
		switch (result)
		{
			case NSAlertDefaultReturn:
				[NSApp terminate: self];
			case NSAlertAlternateReturn:
				goto relaunchProcess;
			default:
				break;
		}
	}
}

/*
 * Config file private methods
 */

/** <p>Finds the Etoile system config file for the receiver and starts the 
    file's monitoring (watching for changes to the file).</p>
    <p>The config file is located in the following order:
    <enum>
    <item>first the user defaults database is searched for a key named 
    "EtoileSystemTaskListFile". The path may contain a '~' abbreviation - this 
     will be expanded according to standard shell expansion rules.</item>
    <item>next, the code looks for the file in
    $GNUSTEP_USER_ROOT/Etoile/SystemTaskList.plist</item>
    <item>next, the code tries all other domains' Library subdirectory
    "Etoile/SystemTaskList.plist"</item>
    <item>if even that fails, the file "SystemTaskList.plist" is looked
    for inside the app bundle's resources files.</item>
    </enum></p>
    <p>If everything fails, no process set is loaded and a warning message is
    printed.</p> */
- (void) findConfigFileAndStartUpdateMonitoring
{
	NSString *tmp;
	NSString *configPath;
	NSString *suffix;
	NSEnumerator *e;
	NSMutableArray *searchPaths = [NSMutableArray array];
	NSFileManager *fm = [NSFileManager defaultManager];

	NSDebugLLog(@"SCSystem", @"Looking for config file");
	
	/* Try looking in the user defaults */
	tmp = [[NSUserDefaults standardUserDefaults]
		objectForKey: @"EtoileSystemTaskListFile"];
	if (tmp != nil)
	{
		[searchPaths addObject: [tmp stringByExpandingTildeInPath]];
	}
	
	suffix = [@"Etoile" stringByAppendingPathComponent: @"SystemTaskList.plist"];
	/* If that fails, try
	   $GNUSTEP_USER_ROOT/Library/Etoile/SystemTaskList.plist */
	tmp = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
		NSUserDomainMask, YES) objectAtIndex: 0];
	[searchPaths addObject: [tmp stringByAppendingPathComponent: suffix]];
	
	/* And if that fails, try all domains */
	e = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
		NSLocalDomainMask | NSNetworkDomainMask | NSSystemDomainMask, YES)
		objectEnumerator];
	while ((tmp = [e nextObject]) != nil)
	{
		[searchPaths addObject: [tmp stringByAppendingPathComponent: suffix]];
	}
	
	/* Finally, try the application bundle's SystemTaskList.plist resource */
	tmp = [[NSBundle mainBundle] pathForResource: @"SystemTaskList" 
	                                      ofType: @"plist"];
	if (tmp != nil)
	{
		[searchPaths addObject: tmp];
	}
	
	e = [searchPaths objectEnumerator];
	while ((configPath = [e nextObject]) != nil)
	{
		if ([fm isReadableFileAtPath: configPath])
		{
			break;
		}
	}
	
	if (configPath != nil)
	{
		NSInvocation * inv;
	
		ASSIGN(configFilePath, configPath);

		NSDebugLLog(@"SCSystem", @"Triggering config monitoring");

		// NOTE: The next line corrupts the stack frame and leads to really 
		// strange segfaults related to gnustep lock objects or thread 
		// dictionary.
		//inv = NS_MESSAGE(self, checkConfigFileUpdate);
		inv = [[NSInvocation alloc] initWithTarget: self selector: 
			@selector(checkConfigFileUpdate)];
		AUTORELEASE(inv);
		ASSIGN(monitoringTimer, [NSTimer scheduledTimerWithTimeInterval: 2.0
		                                                     invocation: inv
		                                                        repeats: YES]);
	}
	else
	{
		NSLog(_(@"WARNING: no usable workspace process set file found. "
			@"I'm not going to do workspace process management."));
	}
}

/** This method is called by -loadConfigFile. The parsing of the config file 
    and the update of the running processes is let to 
    -synchronizeProcessesWithConfigFile method. */
- (void) checkConfigFileUpdate
{
	NSDate *latestModificationDate = [[[NSFileManager defaultManager]
		fileAttributesAtPath: configFilePath traverseLink: YES]
		fileModificationDate];

	/* We discard automatic synchronization with config file when we are in the
	   middle of any process launch. */
	if (_launchQueueScheduled)
		return;
	
	if ([latestModificationDate compare: modificationDate] ==
		NSOrderedDescending)
	{
		NSDebugLLog(@"SCSystem",
			@"Config file %@ changed, reloading...", configFilePath);
	
		[self synchronizeProcessesWithConfigFile];
	 }
}

/** Refreshes the processes list from the config file and modifies the running 
    processes accordingly by killing those which are not supposed to be there
    and starts the new ones. */
- (void) synchronizeProcessesWithConfigFile
{
	NSDictionary *newProcessTable = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager]
		fileAttributesAtPath: configFilePath traverseLink: YES];

	NSDebugLLog(@"SCSystem", @"Synchronizing processes with config file...");

	newProcessTable = [NSDictionary dictionaryWithContentsOfFile: configFilePath];
	if (newProcessTable != nil)
	{
		NSEnumerator *e = nil;
		NSString *domain = nil;

		/* Kill any old, left-over processes or changed processes.
		   NOTE: we can't use -keyEnumerator here, because it isn't guaranteed
		   that the array over which the enumerator enumerates won't change as
		   we remove left-over process entries from the underlying dict. */
		e = [[_processes allKeys] objectEnumerator];
		while ((domain = [e nextObject]) != nil)
		{
			SCTask *oldEntry = [_processes objectForKey: domain];
			SCTask *newEntry = [newProcessTable objectForKey: domain];

			/* If this entry isn't defined in the config file now, we must stop it. */
			if (newEntry == nil)
			{
				[[NSNotificationCenter defaultCenter] removeObserver: self
					name: nil object: oldEntry];

				// NOTE: The next line is equivalent to [oldEntry terminate]; 
				// with extra checks.
				[self stopProcessWithDomain: domain error: NULL];
				[_processes removeObjectForKey: domain];
			}
		}

		/* Afterwards bring in new processes */
		e = [newProcessTable keyEnumerator];
		while ((domain = [e nextObject]) != nil)
		{
			if ([_processes objectForKey: domain] == nil)
			{
				NSDictionary *processInfo = [newProcessTable objectForKey: domain]; 
				NSString *launchPath = [processInfo objectForKey: @"LaunchPath"];
				NSString *launchIdentity = [processInfo objectForKey: @"UserName"];
				int launchPriority = [[processInfo objectForKey: @"LaunchPriority"] intValue];
				BOOL launchNow = [[processInfo objectForKey: @"OnStart"] boolValue];
				BOOL launchLazily = [[processInfo objectForKey: @"OnDemand"] boolValue];

				/* Now we create the new task with paramaters supplied in the 
				  config file. */
				SCTask *entry = [SCTask taskWithLaunchPath: launchPath 
				                                  priority: launchPriority
				                                   onStart: launchNow
				                                  onDemand: launchLazily
				                              withUserName: launchIdentity];

				[entry setArguments: [processInfo objectForKey: @"Arguments"]];
				// FIXME: 'Persistent' key support should be added.
				if (entry != nil)
					[_processes setObject: entry forKey: domain];

				/* When the session has already been started, we can start the
				   process immediately, because no launch queue is going to 
				   collect processes to launch them. */
				if (_launchQueueScheduled == NO)
					[self startProcessWithDomain: domain error: NULL];
			}
		}
	}
	else
	{
		NSLog(_(@"WARNING: unable to read SystemTaskList file."));
	}

	ASSIGN(modificationDate, [fileAttributes fileModificationDate]);
}

/** <p>Notification method invoked when a workspace process terminates. This 
    method causes the given process to be relaunched again. Note the process 
    isn't relaunched when it is stopped by calling -stopProcessForDomain:.</p>
    <p>Take note this notification is not related to 
    NSTaskDidTerminateNotification which is usually sent soon after the task 
    launch.</p> */
- (void) processTerminated: (NSNotification *)notif
{
	SCTask *task = [notif object];
	NSString *domain = [[_processes allKeysForObject: task] objectAtIndex: 0];

	NSDebugLLog(@"SCSystem", @"Process %@ terminated", [task name]);

	/* We relaunch every processes that exit and still referenced by the 
	    process table, unless they are special daemons launched on demand 
	    (in other words, not always running). */
	// FIXME: Checks the process isn't stopped by -stopProcessForDomain:.
	if (domain != nil && [task launchOnDemand] == NO)
	{
	    //[self startProcessWithDomain: domain error: NULL];
	}
}

@end
