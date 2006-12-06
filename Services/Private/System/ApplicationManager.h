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

#import <Foundation/Foundation.h>

@interface ApplicationManager : NSObject
{
  /**
   * This dictionary holds information about all launched applications.
   * Keys in it are application names, and values are dictionaries
   * describing various information about the launched application.
   *
   * The value dictionary contains the following keys:
   *
   * {
   *   @"NSApplicationName" = "<app-name>";
   *   @"NSApplicationPath" = "<app-path>";
   *   @"NSApplicationProcessIdentifier" = (NSNumber *) PID;
   * }
   *
   * When an application is starting up, it's information dictionary
   * does not contain the @"NSApplicationProcessIdentifier" - that will
   * be added later on when the application is running.
   */
  NSMutableDictionary * launchedApplications;

  /**
   * This timer fires every second, when we check whether our registered
   * apps are still alive. The workspace server takes note of apps shutting
   * down in two ways:
   *
   * - receiving an NSWorkspaceDidTerminateApplicationNotification (if the
   *   app terminated gracefully)
   * - or simply seing it's PID disappear from the system (in case it crashed)
   *
   * in the latter case, this object posts an
   * NSWorkspaceDidTerminateApplicationNotification to make up for the app
   * which died and could do it.
   */
  NSTimer * autocheckTimer;
  
  NSMutableDictionary *waitedApplications;
  NSMutableDictionary *terminateLaterTimers;
  NSLock *terminateAllLock;
}

+ sharedInstance;

- (NSArray *) launchedApplications;

- (void) noteApplicationLaunched: (NSNotification *) notif;
- (void) noteApplicationTerminated: (NSNotification *) notif;
- (void) checkLiveApplications;

- (void) terminateAllApplicationsOnOperation: (NSString *) operation;

@end
