
#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSNotification, MenuBarWindow;

extern MenuBarWindow * ServerMenuBarWindow;

@interface Controller : NSObject

+ (NSRect) menuBarWindowFrame;
+ (MenuBarWindow *) sharedMenuBarWindow;

- (void) applicationDidFinishLaunching: (NSNotification *) notif;

- (void) windowDidMove: (NSNotification *) notif;

@end
