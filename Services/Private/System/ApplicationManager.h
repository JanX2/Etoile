#import <Foundation/Foundation.h>

@class NSMutableDictionary,
       NSDictionary,
       NSArray,
       NSMutableArray,
       NSString,
       NSNotification,
       NSTimer;

@class NSTableView,
       NSTableColumn;

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
}

+ sharedInstance;

- (NSArray *) launchedApplications;

- (void) noteApplicationLaunched: (NSNotification *) notif;
- (void) noteApplicationTerminated: (NSNotification *) notif;
- (void) checkLiveApplications;

- (BOOL) gracefullyTerminateAllApplicationsOnOperation: (NSString *) operation;

@end
