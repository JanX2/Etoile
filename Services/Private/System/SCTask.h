/*
	SCTask.h
 
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

#import <Foundation/Foundation.h>


/** Task/Process Info Dictionary Schema
    
    option                      object type

    LaunchPath                  NSString
    Arguments                   NSArray 
    UserName (or Identity)      NSString
    OnStart                     NSNumber/BOOL (<*BN> is NO and <*BY> is YES)
    OnDemand                    NSNumber/BOOL (<*BN> is NO and <*BY> is YES)
    Persistent                  NSNumber/BOOL (<*BN> is NO and <*BY> is YES)
    Hidden                      NSNumber/BOOL (<*BN> is NO and <*BY> is YES)

    A 'Persistent' process is a task which is restarted on system boot if it
    was already running during the previous session. It is usually bound to 
    tasks running in background.
  */

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
	int launchPriority;
	BOOL launchOnStart;
    BOOL launchOnDemand;
    BOOL hidden;
    BOOL stopped;

	BOOL isNSApplication;
	BOOL launchFinished;

	NSDate *launchDate;
	NSTimeInterval runTime;
	int launchFailureCount;
}

+ (SCTask *) taskWithLaunchPath: (NSString *)path;
+ (SCTask *) taskWithLaunchPath: (NSString *)path priority: (int)level
	onStart: (BOOL)now onDemand: (BOOL)lazily withUserName: (NSString *)user;


+ (SCTask *) taskWithTask: (SCTask *)aTask;

- (void) launchForDomain: (NSString *)domain;

- (NSString *) name;
- (NSString *) path;

- (int) launchPriority;
- (BOOL) launchOnStart;
- (BOOL) launchOnDemand;
- (BOOL) isHidden;

- (BOOL) isStopped;

- (NSTimeInterval) runInterval;
- (NSTimeInterval) launchTimeOut;
- (int) launchFailureCount;

@end
