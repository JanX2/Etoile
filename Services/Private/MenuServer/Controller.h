
#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSNotification, MenuBarWindow;

enum {
  MenuBarHeight = 21
};

extern MenuBarWindow * ServerMenuBarWindow;

@interface Controller : NSObject

+ (NSRect) menuBarWindowFrame;
+ (MenuBarWindow *) sharedMenuBarWindow;

- (void) applicationDidFinishLaunching: (NSNotification *) notif;

- (void) windowDidMove: (NSNotification *) notif;

@end
