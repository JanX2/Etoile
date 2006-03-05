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

/* The current domain scheme 'etoilesystem.tool' and 'etoilesystem.application'
   is work ins progress and doesn't reflect the final scheme to be used when 
   CoreObject will be ready. */


@interface NSTask (EtoileSystem)
+ (NSTask *) taskWithLaunchPath: (NSString *)path;
- (void) launchWithOpentoolUtility;
- (void) launchWithOpenappUtility;
- (void) launchForDomain: (NSString *)domain;
@end

@implementation NSTask (EtoileSystem)

+ (NSTask *) taskWithLaunchPath: (NSString *)path
{
    NSTask *newTask = [[NSTask alloc] init];
    [newTask setLaunchPath: path];
    
    return [newTask autorelease];
}

// - (void) launchWithOpenUtility

- (void) launchWithOpentoolUtility
{
    NSArray *args = [NSArray arrayWithObjects: [self launchPath], nil];
    
    [self setLaunchPath: @"opentool"];
    [self setArguments: args];
    [self launch];
}

- (void) launchWithOpenappUtility
{
    NSArray *args = [NSArray arrayWithObjects: [self launchPath], nil];
    
    [self setLaunchPath: @"openapp"];
    [self setArguments: args];
    [self launch];
}

- (void) launchForDomain: (NSString *)domain
{
    /* At later point, we should check the domain to take in account security.
       Domains having usually an associated permissions level. */

    if ([domain hasPrefix: @"etoilesystem.tool"])
    {
        [self launchWithOpentoolUtility];
    }
    else if ([domain hasPrefix: @"etoilesystem.application"])
    {
        [self launchWithOpenappUtility];
    }
    else
    {
        [self launch]; // NOTE: Not sure we should do it
    }
}

@end

@implementation SCSystem

- (id) init
{
    return [self initWithArguments: nil];
}

- (id) initWithArguments: (NSArray *)args
{
    if ((self = [super init]) != nil)
    {
        _processes = [[NSMutableDictionary alloc] initWithCapacity: 20];
         
        /* We register the core processes */
        [_processes setObject: [NSTask taskWithLaunchPath: @"gdomap"] 
            forKey: @"etoilesystem.tool.gdomap"];
        [_processes setObject: [NSTask taskWithLaunchPath: @"gpbs"] 
            forKey: @"etoilesystem.tool.gpbs"];
        [_processes setObject: [NSTask taskWithLaunchPath: @"gdnc"] 
            forKey: @"etoilesystem.tool.gdnc"];
        [_processes setObject: [NSTask taskWithLaunchPath: @"Azalea"] 
            forKey: @"etoilesystem.application.azalea"];
        [_processes setObject: [NSTask taskWithLaunchPath: @"EtoileMenuServer"] 
            forKey: @"etoilesystem.application.menuserver"];
        
        return self;
    }
    
    return nil;
}

+ (SCSystem *) sharedInstance
{
    return [[SCSystem alloc] init];
}

- (void) dealloc
{
    DESTROY(_processes);
    
    [super dealloc];
}

- (void) run
{
    NSEnumerator *e;
    NSString *domain;
    
    /* We start core processes */
    e = [[_processes allKeys] objectEnumerator];
    while ((domain = [e nextObject]) != nil)
    {
        [self startProcessWithDomain: domain];
    }
}

// - (BOOL) startProcessWithDomain: (NSString *)domain 
//     arguments: (NSArray *)args;

- (BOOL) startProcessWithDomain: (NSString *)domain
{
    NSTask *process = [_processes objectForKey: domain];
    /* We should pass process specific flags obtained in arguments (and the
       ones from main function probably too) */
    NSArray *args = [NSArray arrayWithObjects: nil];
    
    /* if ([process isRunning] == NO)
           Look for an already running process with the same name.
       Well, I'm not sure we should do this, but it could be nice, we would 
       have to identify the process in one way or another (partially to not
       compromise the security). */
    
    /*
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *err = [pipe fileHandleForReading];
    NSMutableData *result = [NSMutableData dataWithCapacity: 200];
    NSData *resultPart;
    
    [process setStandardError: err]; */
    [process setArguments: args];
    [process launchForDomain: domain];

    /* FIXME: Not really interesting, the errors are already logged by 
       subprocessses in EtoileSystem error ouput.
    
    while ((resultPart = [err availableData]) != nil)
    {
        [result appendData: resultPart];
    } 

    NSLog([[[NSString alloc] 
        initWithData: result encoding: NSUTF8StringEncoding] autorelease]);
     */
    
    return YES;
}

- (BOOL) restartProcessWithDomain: (NSString *)domain
{
    BOOL restarted;
    
    restarted = [self stopProcessWithDomain: domain];
    
    if (restarted)
        restarted = [self restartProcessWithDomain: domain];
        
    return restarted;
}

- (BOOL) stopProcessWithDomain: (NSString *)domain
{
    NSTask *process = [_processes objectForKey: domain];
    
    if ([process isRunning])
    {
        [process terminate];
        
        if ([process isRunning] == NO)
            return YES;
    }
    
    return NO;
}

- (BOOL) suspendProcessWithDomain: (NSString *)domain
{
    NSTask *process = [_processes objectForKey: domain];
    
    if ([process isRunning])
    {
        return [process suspend];
    }
    
    return NO;
}

- (BOOL) registerProcessForDomain: (NSString *)domain
{
    return NO;
}

- (BOOL) unregisterProcessForDomain: (NSString *)domain
{
    return NO;
}

@end
