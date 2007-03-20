/*
	EtoileSystem.h
 
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

#import <Foundation/Foundation.h>

/* Domains are related to CoreObject domains.
   This process is going to be itself registered in CoreObject server under the
   simple 'etoilesystem' entry. Every other core processes related objects will
   have to be registered under this namespace.
   Finally it is logically in charge to start the CoreObject server. */

/** Task/Process Info Dictionary Schema
    
    option                      object type

    LaunchPath                  NSString
    Arguments                   NSArray 
    UserName (or Identity)      NSString
    Priority                    NSNumber
    OnStart                     NSNumber/BOOL (<*BN> is NO and <*BY> is YES)
    OnDemand                    NSNumber/BOOL (<*BN> is NO and <*BY> is YES)
    Persistent                  NSNumber/BOOL (<*BN> is NO and <*BY> is YES)
    Hidden                      NSNumber/BOOL (<*BN> is NO and <*BY> is YES)

    Priority --> All the tasks are launched sequentially by ascending priority
    order. When the priority values are identical, then they are launched in 
    parallel. For such tasks launch order becomes unpredictable.

    OnStart --> 'YES' means the task is launched only when a new session is 
    initiated as when the user logs in or launches a project. Default value
    is 'YES'. 

    OnDemand --> 'YES' means the task is launched only when the user or some
    applications request it. Default value is 'NO'. If you set both 'OnStart' 
    and 'OnDemand' to 'YES', your task will be launched at the beginning of the
    session but won't restarted automatically when it terminates. You can use
    this flag combination to let the user specify favorite applications which
    get launched at login time.

    Persistent --> 'YES' means the task will be restarted on system boot if it
    was already running during the previous session. It is usually bound to 
    tasks running in background. 'Default value is 'NO'.

    Hidden --> 'YES' means the task is going to be unvisible on user side. Not
    listed as part of any kind of running application list specific to the 
    user. 'Default value is 'NO'.
  */

extern NSString * const EtoileSystemServerName;

@interface SCSystem : NSObject
{
    NSMutableDictionary *_processes; /* Main data structure */
	NSMutableArray *_launchQueue;
	NSMutableArray *_launchGroup;

    /* Config file handling related ivars */
    NSTimer *monitoringTimer;
    NSString *configFilePath;
    NSDate *modificationDate;
	
	/* DO support */
	//NSConnection *serverConnection;
	NSConnection *clientConnection;
}

+ (SCSystem *) sharedInstance;

- (id) initWithArguments: (NSArray *)args;

- (BOOL) startProcessWithDomain: (NSString *)domain error: (NSError **)error;
- (BOOL) restartProcessWithDomain: (NSString *)domain error: (NSError **)error;
- (BOOL) stopProcessWithDomain: (NSString *)domain error: (NSError **)error;
- (BOOL) suspendProcessWithDomain: (NSString *)domain error: (NSError **)error;

- (void) run;

- (void) loadConfigList;
- (void) saveConfigList;

- (NSArray *) maskedProcesses;
- (BOOL) terminateAllProcessesOnOperation: (NSString *)op;

- (oneway void) logOutAndPowerOff: (BOOL) powerOff;
- (void) replyToLogOutOrPowerOff: (NSDictionary *)info;

/* SCSystem server daemon set up methods */

+ (id) serverInstance;
+ (BOOL) setUpServerInstance: (id)instance;

@end
