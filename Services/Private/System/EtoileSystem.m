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
static id proxyInstance = nil;
static NSString *SCSystemNamespace = nil;
NSString * const EtoileSystemServerName = @"etoile_system";

static BOOL powerOffRequested = NO;

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

@interface SCSystem (HelperMethodsPrivate)
- (void) checkConfigFileUpdate;
- (void) findConfigFileAndStartUpdateMonitoring;

- (void) synchronizeProcessesWithConfigFile;

- (void) startProcessWithUserFeedbackForDomain: (NSString *)domain;
@end

/** SCTask represents a task/process unit which could be running or not. Their 
    instances are stored in _processes ivar of SCSystem singleton. */

// FIXME: @class NSConcreteTask; this triggers a GCC segmentation fault when 
// used in tandem with SCTask : NSConcreteTask. It arises with 
// NSConcreteUnixTask directly too.
@interface NSConcreteUnixTask : NSTask /* Extracted from NSTask.m */
{
  char	slave_name[32];
  BOOL	_usePseudoTerminal;
}
@end

// HACK: We subclass NSConcreteTask which is a macro corresponding to 
// NSConcreteUnixTask on Unix systems, because NSTask is a class cluster which
// doesn't implement -launch method.

@interface SCTask : NSConcreteUnixTask // NSConcreteTask
{
    NSString *path; /* The path initially given to the task (or deduced when a 
                       name was passed) */
    NSString *launchIdentity;
    BOOL launchOnDemand;
    BOOL hidden;
    BOOL stopped;
}

+ (SCTask *) taskWithLaunchPath: (NSString *)path;
+ (SCTask *) taskWithLaunchPath: (NSString *)path onDemand: (BOOL)lazily withUserName: (NSString *)user;

- (void) launchForDomain: (NSString *)domain;

- (NSString *) name;
- (NSString *) path;

- (BOOL) launchOnDemand;
- (BOOL) isHidden;

- (BOOL) isStopped;

@end

@implementation SCTask

+ (NSString *) pathForName: (NSString *)name
{
    NSMutableArray *searchPaths = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSEnumerator *e;
    NSString *path = nil;
    BOOL isDir;

    [searchPaths addObjectsFromArray: 
        NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, 
        NSAllDomainsMask, YES)];

    [searchPaths addObjectsFromArray: 
        NSSearchPathForDirectoriesInDomains(GSToolsDirectory, 
        NSAllDomainsMask, YES)];

    NSLog(@"Searching for tool or application inside paths: %@", searchPaths);

    e = [searchPaths objectEnumerator];
    while ((path = [e nextObject]) != nil)
    {
        /* -stringByStandardizingPath removes double-slash, they occurs when 
           GNUSTEP_SYSTEM_ROOT is equal to '/' */
        path = [[path stringByAppendingPathComponent: name] stringByStandardizingPath];
        
        if ([fm fileExistsAtPath: path isDirectory: &isDir])
        {
            NSLog(@"Found tool or application at path: %@", path);
            return path;
        }

        path = [path stringByAppendingPathExtension: @"app"];

        if ([fm fileExistsAtPath: path isDirectory: &isDir])
        {
            NSLog(@"Found tool or application at path: %@", path);
            return path;
        }
    }

    return nil;
}

+ (SCTask *) taskWithLaunchPath: (NSString *)path
{
    return [self taskWithLaunchPath: path onDemand: NO withUserName: nil];
}

+ (SCTask *) taskWithLaunchPath: (NSString *)path onDemand: (BOOL)lazily 
    withUserName: (NSString *)identity
{
    SCTask *newTask = [[SCTask alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    
    /* If a name has been given as the launch path, we try to convert it to a 
       path. */
    if ([[path pathComponents] count] == 1)
    {
        NSString *pathFound = [SCTask pathForName: path];

        if (pathFound != nil)
        {
            ASSIGN(newTask->path, pathFound);
        }
        else
        {
            NSLog(@"SCTask does not found a path for tool or application name: %@", path);
        }
    }
    else
    {
        ASSIGN(newTask->path, path);
    }
    /* We check whether the launch path references an executable path or just
       a directory which could be a potential application bundle. */
    if ([fm fileExistsAtPath: [newTask path] isDirectory: &isDir] && isDir)
    {
        NSBundle *bundle = [NSBundle bundleWithPath: [newTask path]];
        
        if (bundle != nil)
        {
            [newTask setLaunchPath: [bundle executablePath]];
        }
        else
        {
            NSLog(@"Failed to create an SCTask with launch path %@ because it \
                does not reference an application bundle.");
        }
    }
    else
    {
        [newTask setLaunchPath: [newTask path]];
    }

    ASSIGN(newTask->launchIdentity, identity);
    
    newTask->launchOnDemand = lazily;
    newTask->hidden = YES;
    newTask->stopped = NO;
    
    return [newTask autorelease];
}

- (void) dealloc
{
	TEST_RELEASE(path);
	TEST_RELEASE(launchIdentity);
	
	[super dealloc];
}

- (void) launchForDomain: (NSString *)domain
{
    /* At later point, we should check the domain to take in account security.
       Domains having usually an associated permissions level. */

    [self launch];

    stopped = NO;

    /*  appBinary = [ws locateApplicationBinary: appPath];

      if (appBinary == nil)
        {
          SetNonNullError (error, WorkspaceProcessManagerProcessLaunchingError,
            _(@"Unable to locate application binary of application %@"),
            appName);

          return NO;
        } */
}

/** Returns the path used to create the task, it is identical to launch 
    path most of time, unless the path given initially references an 
    application bundle and not an executable path directly. */
- (NSString *) path
{
	return [[path copy] autorelease];
}

/** Returns the name of the task executable based on -path value. */
- (NSString *) name
{
	NSString *name = 
		[[NSFileManager defaultManager] displayNameAtPath: [self path]];

	return name;
}

- (BOOL) launchOnDemand
{
    return launchOnDemand;
}

- (BOOL) isHidden
{
    return hidden;
}

- (BOOL) isStopped
{
    return stopped;
}

- (void) terminate
{
    stopped = YES;
    [super terminate];
}

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

+ (id) serverInstance
{
	return serverInstance;
}

+ (BOOL) setUpServerInstance: (id)instance
{
	ASSIGN(serverInstance, instance);

	/* Finish set up by exporting server instance through DO */
	NSConnection *theConnection = [NSConnection defaultConnection];
	
	[theConnection setRootObject: instance];
	if ([theConnection registerName: SCSystemNamespace] == NO) 
	{
		// FIXME: Take in account errors here.
		NSLog(@"Unable to register the system namespace %@ with DO", 
			SCSystemNamespace);

		return NO;
	}
	[theConnection setDelegate: self];
	
	NSLog(@"Setting up SCSystem server instance");
	
	return YES;
}

/** Reserved for client side. It's mandatory to have call -setUpServerInstance: 
    before usually in the server process itself. */
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

- (id) initWithArguments: (NSArray *)args
{
    if ((self = [super init]) != nil)
    {
        _processes = [[NSMutableDictionary alloc] initWithCapacity: 20];

        [self findConfigFileAndStartUpdateMonitoring];
        if (configFilePath != nil)
        {
            /* We register the core processes */
            // FIXME: Takes care to standardize Etoile core processes naming scheme.
            [self synchronizeProcessesWithConfigFile];
        }

        return self;
    }
    
    return nil;
}

- (void) dealloc
{
    DESTROY(_processes);

    TEST_RELEASE(monitoringTimer);
    TEST_RELEASE(configFilePath);
    TEST_RELEASE(modificationDate);
    
    [super dealloc];
}

- (void) run
{
    NSEnumerator *e;
    NSString *domain = nil;
    
    /* We start core processes */
    e = [[_processes allKeys] objectEnumerator];
    while ((domain = [e nextObject]) != nil)
    {
        SCTask *process = [_processes objectForKey: domain];
        
        if ([process launchOnDemand] == NO)
            [self startProcessWithDomain: domain error: NULL]; //FIXME: Handles error properly.
    }
    
    /* We trigger the ApplicationManager singleton creation in order it 
       starts to monitor user applications. The return value is ignored. */
    [ApplicationManager sharedInstance];
}

// - (BOOL) startProcessWithDomain: (NSString *)domain 
//     arguments: (NSArray *)args;

/**
 * Launches a workspace process.
 *
 * @param processDescription The description of the process which to launch.
 * @param error A pointer to an NSError variable which will be filled with
 *      an NSError instance in case of a launch error.
 *
 * @return YES if the launch succeeds, NO if it doesn't and indicates the
 *      reason in the ``error'' argument.
 */
- (BOOL) startProcessWithDomain: (NSString *)domain error: (NSError **)error
{
    SCTask *process = [_processes objectForKey: domain];
    /* We should pass process specific flags obtained in arguments (and the
       ones from main function probably too) */
    NSArray *args = [NSArray arrayWithObjects: nil];
    
	/* Look for an already running process with the same domain.
	   Well, I'm not sure we should do this, but it could be nice, we would 
	   have to identify the process in one way or another (partially to not
	   compromise the security). */
	if (process == nil)
	{
		// FIXME: Set up an error explaing no process has been bound to this
		// domain.
		return NO;
	}

	NSDebugLLog(@"SCSystem", @"Trying to start process %@ associated with domain %@", 
		[process path], domain);
		
    if ([process isRunning])
	{
		// FIXME: Set up an error explaing a process is already running for
		//  this domain.
		return NO;
	}
	else
	{
		NSDebugLLog(@"SCSystem", @"Will try to restart this process that already exited");
	}

    // NOTE: the next line triggers an invalid argument exception, although the
    // array isn't nil.
    // [process setArguments: args];

    NS_DURING
        [process launchForDomain: domain];
    NS_HANDLER
        SetNonNullError (error, EtoileSystemTaskLaunchingError,
            _(@"Error launching program at %@: %@"), [process path],
            [localException reason]);

        return NO;
    NS_ENDHANDLER

    [[NSNotificationCenter defaultCenter] addObserver: self
        selector: @selector(processTerminated:) 
            name: NSTaskDidTerminateNotification
          object: process];
    
    return YES;
}

- (BOOL) restartProcessWithDomain: (NSString *)domain error: (NSError **)error
{
    BOOL stopped = NO;
    BOOL restarted = NO;
    
    stopped = [self stopProcessWithDomain: domain error: NULL];
    
    /* The process has been properly stopped or was already, then we restart it now. */
    if (stopped)
        restarted = [self restartProcessWithDomain: domain error: NULL];

    return restarted;
}

- (BOOL) stopProcessWithDomain: (NSString *)domain error: (NSError **)error
{
    NSTask *process = [_processes objectForKey: domain];
    
	NSDebugLLog(@"SCSystem", @"Trying to terminate process %@ with domain %@", 
		[process launchPath], domain);

    if ([process isRunning])
    {
		NSDebugLLog(@"SCSystem", @"Terminating process now");

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
            return YES;
    }
    
    return NO;
}

- (BOOL) suspendProcessWithDomain: (NSString *)domain error: (NSError **)error
{
    NSTask *process = [_processes objectForKey: domain];
    
    if ([process isRunning])
    {
        return [process suspend];
    }
    
    return NO;
}

- (void) loadConfigList
{
    [self checkConfigFileUpdate];
}

- (void) saveConfigList
{
    // TODO: Write the code to sync the _processes ivar and the config file
}

/**
 * Returns a list of Etoile system processes invisible to the user.
 *
 * This list is used by the application manager to determine which
 * apps it should ommit from its output and from terminating when
 * shutting down gracefully.
 *
 * @return An array of process names of processes to be kept masked
 */
- (NSArray *) maskedProcesses
{
    NSMutableArray *array = 
            [NSMutableArray arrayWithCapacity: [_processes count]];
    NSEnumerator *e = [_processes objectEnumerator];
    SCTask *processesEntry;
    
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

/**
 * Gracefully terminates all workspace processes at log out or power
 * off time.
 *
 * @return YES if the log out/power off operation can proceed, NO
 *      if an app requested the operation to be halted.
 */
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

- (oneway void) logOutAndPowerOff: (BOOL) powerOff
{
	NSString * operation;

	NSDebugLLog(@"SCSystem", @"Log out requested");

	if (powerOff == NO)
	{
		operation = _(@"Log Out");
	}
	else
	{
		operation = _(@"Power Off");
		powerOffRequested = YES;
	}

	// Ask to close all applications gracefully and wait for a reply
	/*[NSThread detachNewThreadSelector: @selector(terminateAllApplicationsOnOperation:) 
		toTarget: [ApplicationManager sharedInstance] withObject: operation];*/
	[self replyToLogOutOrPowerOff: nil];
}

- (void) replyToLogOutOrPowerOff: (NSString *)appName
{
	if (appName == nil)
	{
		// All applications have been terminated, time to terminate our own tasks
		BOOL end = [self terminateAllProcessesOnOperation: nil];
		
		if (powerOffRequested)
		{
          // TODO: initiate the power off process here
		}

		// Time to put an end to our own life.
		exit(0);
	}
	else
	{
		NSRunAlertPanel (_(@"Log out or shut down cancelled"),
			_(@"Service %@ does not reply or quit in the 1 minute delay available \
				after asking to do so."),
              nil, nil, nil, appName);
	}
}

@end

/*
 * Helper methods for handling process list and monitoring their config files
 */

@implementation SCSystem (HelperMethodsPrivate)

/**
 * Launches a workspace process. This method is special in that if launching
 * the process fails, it queries the user whether to log out (fatal failure),
 * retry launching it or ignore it.
 *
 * @param processDescription A description dictionary of the process
 *      which to launch.
 */
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

/**
 * Finds the Etoile system config file for the receiver and starts the file's
 * monitoring (watching for changes to the file).
 *
 * The config file is located in the following order:
 *
 * - first the user defaults database is searched for a key named
 *      "EtoileSystemTaskListFile". The path may contain a '~'
 *      abbreviation - this will be expanded according to standard
 *      shell expansion rules.
 * - next, the code looks for the file in
 *      $GNUSTEP_USER_ROOT/Etoile/SystemTaskList.plist
 * - next, the code tries all other domains' Library subdirectory
 *      "Etoile/SystemTaskList.plist"
 * - if even that fails, the file "SystemTaskList.plist" is looked
 *      for inside the app bundle's resources files.
 *
 * If everything fails, no process set is loaded and a warning message
 * is printed.
 */
- (void) findConfigFileAndStartUpdateMonitoring
{
    NSString *tmp;
    NSString *configPath;
	NSString *suffix;
    NSEnumerator *e;
    NSMutableArray *searchPaths = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // try looking in the user defaults
    tmp = [[NSUserDefaults standardUserDefaults]
        objectForKey: @"EtoileSystemTaskListFile"];
    if (tmp != nil)
    {
        [searchPaths addObject: [tmp stringByExpandingTildeInPath]];
    }
    
	suffix = [@"Etoile" stringByAppendingPathComponent: @"SystemTaskList.plist"];
    // if that fails, try
    // $GNUSTEP_USER_ROOT/Library/EtoileWorkspace/WorkspaceProcessSet.plist
    tmp = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
        NSUserDomainMask, YES) objectAtIndex: 0];
	[searchPaths addObject: [tmp stringByAppendingPathComponent: suffix]];
    
    // and if that fails, try all domains
    e = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
        NSLocalDomainMask | NSNetworkDomainMask | NSSystemDomainMask, YES)
        objectEnumerator];
    while ((tmp = [e nextObject]) != nil)
    {
		[searchPaths addObject: [tmp stringByAppendingPathComponent: suffix]];
    }
    
    // finally, try the application bundle's WorkspaceProcessSet.plist resource
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
    
        inv = NS_MESSAGE(self, checkConfigFileUpdate);
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
    and the update of the running processes is let to -synchronizeProcessesWithConfigFile 
    method. */
- (void) checkConfigFileUpdate
{
    NSDate *latestModificationDate = [[[NSFileManager defaultManager]
        fileAttributesAtPath: configFilePath traverseLink: YES]
        fileModificationDate];
    
    if ([latestModificationDate compare: modificationDate] ==
        NSOrderedDescending)
    {
        NSDebugLLog(@"Etoile System",
            @"Config file %@ changed, reloading...", configFilePath);
    
        [self synchronizeProcessesWithConfigFile];
     }
}

/**
 * Refreshes the processes list from the config file and modifies the
 * running processes accordingly - kills those which are not supposed
 * to be there and starts the new ones.
 */
- (void) synchronizeProcessesWithConfigFile
{
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSDictionary *newProcessTable;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager]
            fileAttributesAtPath: configFilePath traverseLink: YES];

    newProcessTable = [NSDictionary dictionaryWithContentsOfFile: configFilePath];
    if (newProcessTable != nil)
    {
        NSEnumerator *e;
        NSString *domain;

      // kill any old, left-over processes or changed processes.
      // N.B. we can't use -keyEnumerator here, because it isn't guaranteed
      // that the array over which the enumerator enumerates won't change
      // as we remove left-over process entries from the underlying dict.
        e = [[_processes allKeys] objectEnumerator];
        while ((domain = [e nextObject]) != nil)
        {
            SCTask *oldEntry = [_processes objectForKey: domain],
            *newEntry = [newProcessTable objectForKey: domain];

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

      // and bring in new processes
        e = [newProcessTable keyEnumerator];
        while ((domain = [e nextObject]) != nil)
        {
            if ([_processes objectForKey: domain] == nil)
            {
                NSDictionary *processInfo = [newProcessTable objectForKey: domain]; 
            
                // FIXME: Add support for Argument and Persistent keys as 
                // described in Task config file schema (see EtoileSystem.h).
                SCTask *entry = [SCTask taskWithLaunchPath: [processInfo objectForKey: @"LaunchPath"] 
                    onDemand: [[processInfo objectForKey: @"OnDemand"] boolValue]
                    withUserName: [processInfo objectForKey: @"UserName"]];

                [_processes setObject: entry forKey: domain];
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

/**
 * Notification method invoked when a workspace process terminates. This method
 * causes the given process to be relaunched again. Note the process isn't
 * relaunched when it is stopped by calling -stopProcessForDomain:.
 */
- (void) processTerminated: (NSNotification *)notif
{
    SCTask *task = [notif object];
    NSString *domain = [[_processes allKeysForObject: task] objectAtIndex: 0];

    /* We relaunch every processes that exit and still referenced by the 
        process table, unless they are special daemons launched on demand 
        (in other words, not always running). */
    // FIXME: Checks the process isn't stopped by -stopProcessForDomain:.
    if (domain != nil && [task launchOnDemand] == NO)
    {
        [self startProcessWithDomain: domain error: NULL];
    }
}

@end
