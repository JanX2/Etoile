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
#import <math.h>

@interface SCTask (Private)
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

    [[NSNotificationCenter defaultCenter] addObserver: newTask
        selector: @selector(taskTerminated:) 
            name: NSTaskDidTerminateNotification
          object: nil];
    
    return [newTask autorelease];
}

/** Returns a new task you can always launch and identical to aTask. The 
    returned task can be launched even if aTask has already been launched. 
    This is useful since SCTask as NSTask can be run only one time. */
+ (SCTask *) taskWithTask: (SCTask *)aTask
{
	SCTask *newTask = [SCTask taskWithLaunchPath: [aTask launchPath] 
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

	TEST_RELEASE(path);
	TEST_RELEASE(launchIdentity);
	TEST_RELEASE(launchDate);
	
	[super dealloc];
}

- (void) launch
{
	launchDate = [[NSDate alloc] init];
	[super launch];
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

- (void) taskTerminated: (NSNotification *)notif
{
	stopped = YES; 

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

@end
