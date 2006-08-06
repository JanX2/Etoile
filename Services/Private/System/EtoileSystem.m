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
    NSString *launchIdentity;
    BOOL launchOnDemand;
}

+ (SCTask *) taskWithLaunchPath: (NSString *)path;
+ (SCTask *) taskWithLaunchPath: (NSString *)path onDemand: (BOOL)lazily withUserName: (NSString *)user;

- (void) launchWithOpentoolUtility;
- (void) launchWithOpenappUtility;
- (void) launchForDomain: (NSString *)domain;

- (BOOL) launchOnDemand;

@end

@implementation SCTask

+ (SCTask *) taskWithLaunchPath: (NSString *)path
{
    return [self taskWithLaunchPath: path onDemand: NO withUserName: nil];
}

+ (SCTask *) taskWithLaunchPath: (NSString *)path onDemand: (BOOL)lazily 
    withUserName: (NSString *)identity
{
    SCTask *newTask = [[SCTask alloc] init];
    
    [newTask setLaunchPath: path];
    ASSIGN(newTask->launchIdentity, identity);
    newTask->launchOnDemand = lazily;
    
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

    if ([domain hasPrefix: @"/etoilesystem/tool"])
    {
        [self launchWithOpentoolUtility];
    }
    else if ([domain hasPrefix: @"/etoilesystem/application"])
    {
        [self launchWithOpenappUtility];
    }
    else
    {
        [self launch]; // NOTE: Not sure we should do it
    }
}

- (BOOL) launchOnDemand
{
    return launchOnDemand;
}

@end

/*
 * Main class SCSystem implementation
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
		NSLog(@"Unable to register the services bar namespace %@ with DO", 
			SCSystemNamespace);

		return NO;
	}

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
         
        /* We register the core processes */
        // FIXME: Takes care to standardize Etoile core processes naming scheme.
        [_processes setObject: [SCTask taskWithLaunchPath: @"gdomap"] 
            forKey: @"/etoilesystem/tool/gdomap"];
        [_processes setObject: [SCTask taskWithLaunchPath: @"gpbs"] 
            forKey: @"/etoilesystem/tool/gpbs"];
        [_processes setObject: [SCTask taskWithLaunchPath: @"gdnc"] 
            forKey: @"/etoilesystem/tool/gdnc"];
        [_processes setObject: [SCTask taskWithLaunchPath: @"Azalea"] 
            forKey: @"/etoilesystem/application/azalea"];
        [_processes setObject: [SCTask taskWithLaunchPath: @"etoile_objectServer"] 
            forKey: @"/etoilesystem/application/menuserver"];
        [_processes setObject: [SCTask taskWithLaunchPath: @"etoile_userSession"] 
            forKey: @"/etoilesystem/application/menuserver"];
        [_processes setObject: [SCTask taskWithLaunchPath: @"etoile_windowServer"] 
            forKey: @"/etoilesystem/application/menuserver"];
        [_processes setObject: [SCTask taskWithLaunchPath: @"EtoileMenuServer"] 
            forKey: @"/etoilesystem/application/menuserver"];  
        
        return self;
    }
    
    return nil;
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
        SCTask *process = [_processes objectForKey: domain];
        
        if ([process launchOnDemand] == NO)
            [self startProcessWithDomain: domain];
    }
}

// - (BOOL) startProcessWithDomain: (NSString *)domain 
//     arguments: (NSArray *)args;

- (BOOL) startProcessWithDomain: (NSString *)domain
{
    SCTask *process = [_processes objectForKey: domain];
    /* We should pass process specific flags obtained in arguments (and the
       ones from main function probably too) */
    NSArray *args = [NSArray arrayWithObjects: nil];
    
    /* if ([process isRunning] == NO)
           Look for an already running process with the same name.
       Well, I'm not sure we should do this, but it could be nice, we would 
       have to identify the process in one way or another (partially to not
       compromise the security). */
    
    [process setArguments: args];
    [process launchForDomain: domain];
    
    return YES;
}

- (BOOL) restartProcessWithDomain: (NSString *)domain
{
    BOOL stopped = NO;
    BOOL restarted = NO;
    
    stopped = [self stopProcessWithDomain: domain];
    
    /* The process has been properly stopped or was already, then we restart it now. */
    if (stopped)
        restarted = [self restartProcessWithDomain: domain];

    return restarted;
}

- (BOOL) stopProcessWithDomain: (NSString *)domain
{
    NSTask *process = [_processes objectForKey: domain];
    
    if ([process isRunning])
    {
        [process terminate];

        /* We check the process has been really terminated before saying so. */
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

- (void) loadConfigList
{

}

- (void) saveConfigList
{

}

@end

/*
 * Helper methods for handling process list and monitoring their config files
 */

@implementation SCSystem (HelperMethodsPrivate)

// FIXME: Insert modified methods from WorkspaceProcessManager by Saso Kiselkov here.

@end
