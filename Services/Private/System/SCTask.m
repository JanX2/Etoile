/*
    SCTask.m
 
    NSTask subclass to encapsulate System specific extensions.
 
    Copyright (C) 2006 Quentin Mathe
 
    Author:  Quentin Mathe <qmathe@club-internet.fr>
    Date:  December 2006

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

#import "SCTask.h"
#import "EtoileSystem.h"
#import <AppKit/AppKit.h> // For NSWorkspaceDidLaunchNotification
#import <math.h>
#import <EtoileFoundation/NSInvocation+Etoile.h>

@interface SCSystem (Private)
- (void) noteApplicationLaunched: (NSNotification *)notif;
@end

@interface SCTask (Private)
- (void) postTaskLaunched;
- (void) taskLaunched: (NSNotification *)notif;
- (void) taskTerminated: (NSNotification *)notif;
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
	return [self taskWithLaunchPath: path priority: 0 onStart: YES onDemand: NO
		withUserName: nil];
}

+ (SCTask *) taskWithLaunchPath: (NSString *)path priority: (int)level 
	onStart: (BOOL)now onDemand: (BOOL)lazily withUserName: (NSString *)identity
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
            NSLog(@"WARNING: SCTask does not found a path for tool or "
				  @"application name: %@", path);
			RELEASE(newTask);
			return nil;
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
            NSLog(@"WARNING: Failed to create an SCTask with launch path %@ "
				  @"because it does not reference an application bundle.");
			RELEASE(newTask);
			return nil;
        }
    }
    else
    {
        [newTask setLaunchPath: [newTask path]];
    }

    ASSIGN(newTask->launchIdentity, identity);

	newTask->launchPriority = level;
    newTask->launchOnDemand = lazily;
    newTask->launchOnStart = now;
    newTask->hidden = YES;
    newTask->stopped = NO;

	// NOTE: We could use a better test than just checking whether an 'app'
	// extension is present or not...
	// pathForApp = [[NSWorkspace sharedWorkspace] fullPathForApplication: [newTask name]];
	if ([[[newTask path] pathExtension] isEqual: @"app"])
		newTask->isNSApplication = YES;
	
	/* To detect whether an AppKit-based process has been really launched or 
	   not, see -taskLaunched:. */
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: newTask
		selector: @selector(taskLaunched:) 
			name: NSWorkspaceDidLaunchApplicationNotification
			object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: newTask
        selector: @selector(taskTerminated:) 
            name: NSTaskDidTerminateNotification
          object: newTask];
    
    return [newTask autorelease];
}

/** Returns a new task you can always launch and identical to aTask. The 
    returned task can be launched even if aTask has already been launched. 
    This is useful since SCTask as NSTask can be run only one time. */
+ (SCTask *) taskWithTask: (SCTask *)aTask
{
	SCTask *newTask = [SCTask taskWithLaunchPath: [aTask launchPath] 
	                                    priority: [aTask launchPriority]
	                                     onStart: [aTask launchOnStart]
	                                    onDemand: [aTask launchOnDemand] 
	                                withUserName: nil];

	[newTask setArguments: [aTask arguments]];
	[newTask setCurrentDirectoryPath: [aTask currentDirectoryPath]];
	[newTask setEnvironment: [aTask environment]];
	[newTask setStandardError: [aTask standardError]];
	[newTask setStandardInput: [aTask standardInput]];
	[newTask setStandardOutput: [aTask standardOutput]];

	newTask->launchFailureCount = aTask->launchFailureCount;

	return newTask;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];

	TEST_RELEASE(path);
	TEST_RELEASE(launchIdentity);
	TEST_RELEASE(launchDate);
	
	[super dealloc];
}

- (NSString *) description
{
	NSString *desc = [self name];

	desc = [desc stringByAppendingFormat: @" %d %@", [self launchPriority], 
		[super description]];

	return desc;
}

- (void) launch
{
	NSDebugLLog(@"SCTask", @"Launching task %@", self);
	launchDate = [[NSDate alloc] init];
	[super launch];
}

- (void) launchForDomain: (NSString *)domain
{
    /* At later point, we should check the domain to take in account security.
       Domains having usually an associated permissions level. */

    [self launch];
    stopped = NO;
	/* For tools, we notify SSCystem of the launch immediately. 
	   For applications, we waits the application reports that it has finished 
	   to launch before notifying SCSystem. 
	   - If the application launch succeds, we catch NSWorkspaceDidLaunchNotification
	     with -taskLaunched: and notify System directly.
	   - If the application launch fails, we catch NSTaskDidTerminateNotification
	     with -taskTerminated: and notify System directly.
	   - If the application launch times out, we use a timer to check the time 
	     out delay with -checkLaunchTimeOut, and notify System directly. This 
	     doesn't the launch failed, but the control must return to the launch 
	     queue otherwise the launch sequence can be blocked... */
	launchFinished = (isNSApplication == NO); //([self isRunning] && isNSApplication == NO);

	if (launchFinished)
	{
		[self postTaskLaunched];
	}
	else /* Wait the launch is fully finished by delaying -postTaskLaunched call */
	{
		NSInvocation *inv = [NSInvocation invocationWithTarget: self 
		                                              selector: @selector(checkLaunchTimeOut)
		                                             arguments: nil];
		/* The run loop retains the timer, then releases it once it has fired */
		[NSTimer scheduledTimerWithTimeInterval: [self launchTimeOut]
		                             invocation: inv
		                                repeats: NO];
	}
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
	NSString *name = nil;
	NSBundle *bundle = [NSBundle bundleWithPath: [self path]];
	NSDictionary *info = [bundle infoDictionary];

	name = [info objectForKey: @"ApplicationName"];
	
	if (name == nil)
		name = [info objectForKey: @"CFBundleName"];

	if (name == nil)
		name = [[NSFileManager defaultManager] displayNameAtPath: [bundle executablePath]];

	/* A last fallback that should always work */
	if (name == nil)
		name = [[NSFileManager defaultManager] displayNameAtPath: [self path]];

	return name;
}

- (int) launchPriority
{
	return launchPriority;
}

- (BOOL) launchOnStart
{
    return launchOnStart;
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

- (void) postTaskLaunched
{
	// NOTE: Incompletely filled userInfo dictionary
	NSDictionary *userInfo = [NSDictionary 
		dictionaryWithObjectsAndKeys: [self path], @"NSApplicationPath", 
		[self name], @"NSApplicationName", nil]; 
	NSNotification *notif = [NSNotification
		notificationWithName: NSWorkspaceDidLaunchApplicationNotification
						object: self
					userInfo: userInfo];

	NSDebugLLog(@"SCTask", @"Synthetize launch notification for task %@", self);

	// FIXME: We should use -sharedInstance, using -serverInstance prevents 
	// SCTask API to be used by a third-party application.
	[[SCSystem serverInstance] noteApplicationLaunched: notif];
}

/** In case no launch notification is posted or the launch is very slow, we 
    return the control to the launch queue to be safe.
    If GDNC is in trouble, this method will ensure the launch sequence continues 
    as expected and doesn't get stalled waiting for a 
    NSWorkspaceDidLaunchApplicationNotification that will never be received. */
- (void) checkLaunchTimeOut
{
	/* The time out timer always fires so we have to ignore it if the launch has 
	   succeeded */
	if (launchFinished)
		return;

	// TODO: Try to handle in a more user-friendly manner... may be by asking 
	// the user for feedback.
	NSLog(@"WARNING: Task %@ launch timed out. Any other tasks to be launched "
		"that depend on it might not run properly.", [self name]);
	
	NSAssert1(stopped == NO, @"Task %@ is wrongly stopped while it is still "
		@"launching", self);
	launchFinished = YES;
	[self postTaskLaunched];
}

/** We detect when an AppKit-based application has finished to launch with this 
    method. Each task instance is set up to listen for 
    NSWorkspaceDidLaunchApplicationNotification. */
- (void) taskLaunched: (NSNotification *)notif
{
	NSString *appName = [[notif userInfo] objectForKey: @"NSApplicationName"];

	if ([appName isEqual: [self name]] == NO)
		return;
	
	NSDebugLLog(@"SCTask", @"Task %@ finished to launch", [self name]);
	
	launchFinished = YES;
	[self postTaskLaunched];
}

- (void) taskTerminated: (NSNotification *)notif
{
	/* For AppKit-based applications which exits before having finished to 
	   launch, we abuse -postTaskLaunched in order to have them properly removed 
	   from the actual launch queue. */
	BOOL wasStillLaunching = (isNSApplication && launchFinished == NO);

	stopped = YES; 
	launchFinished = YES;

	if (wasStillLaunching)
	{
		NSLog(@"WARNING: Failed to launch %@", self);
		[self postTaskLaunched];
	}

	/* We convert launch time to run duration */
	// NOTE: -timeIntervalSinceNow returns a negative value in our case, 
	// therefore we take the absolute value.
	runTime = fabs([launchDate timeIntervalSinceNow]);
	NSDebugLLog(@"SCTask", @"Task %@ terminated with run interval: %f", 
		[self name], runTime);

	/* We update recent launch failure count */
	(runTime < 10) ? launchFailureCount++ : (launchFailureCount = 0);
}

/** Returns the time that elapsed since the launch. If the task is not running
   anymore, it returns the run duration (the interval betwen launch and 
   termination). */
- (NSTimeInterval) runInterval;
{
	if ([self isRunning])
	{
		NSTimeInterval interval = fabs([launchDate timeIntervalSinceNow]);

		NSDebugLLog(@"SCTask", @"-runInterval will return: %f", interval);
		
		return interval;
	}
	else
	{
		return runTime;
	}
}

- (int) launchFailureCount
{
	return launchFailureCount;
}

/** Returns the maximal time limit for which the launch queue can be blocked 
    when a launch is underway. This time limit is set to 5 seconds by default.
    If a launch takes longer to finish than the returned time interval, a 
    warning will be logged, and the control returned to the SCSystem launch 
    queue that will spawn the next task in the queue. */
- (NSTimeInterval) launchTimeOut
{
	return 5.0;	
}

/** Returns self but with retain count incremented by one. NSDictionary keys 
	must conform to NSCopying protocol. This method is implemented to allow 
	task instances to be used in this role. */
- (id) copyWithZone: (NSZone)zone
{
	NSDebugLLog(@"SCTask", @"Copying SCTask %@", self);

	return RETAIN(self);
}

@end
