#import <Foundation/Foundation.h>

@class NSNotification,
       NSString,
       NSArray,
       NSDictionary;

extern NSString * const EtoileWorkspaceServerAppName;

@interface Controller : NSObject

- (void) applicationDidFinishLaunching: (NSNotification *) notif;

- (BOOL) openFile: (NSString *) aFile
  withApplication: (NSString *) appName
    andDeactivate: (BOOL) deactivate;

- (NSArray *) launchedApplications;

- (oneway void) logOutAndPowerOff: (BOOL) powerOff;

@end
