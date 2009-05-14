#import <Foundation/NSString.h>

#ifndef DEFINE_NOTIFICATION
#define DEFINE_NOTIFICATION(x) extern NSString *XCB ## x ##Notification
#endif

DEFINE_NOTIFICATION(WindowDidDestroy);
DEFINE_NOTIFICATION(WindowDidMap);
DEFINE_NOTIFICATION(WindowDidUnMap);
DEFINE_NOTIFICATION(WindowFrameDidChange);
DEFINE_NOTIFICATION(WindowPlacedOnTop);
DEFINE_NOTIFICATION(WindowPlacedOnBottom);

#define XCBNOTIFY(x) \
{\
	NSNotificationCenter *_center = [NSNotificationCenter defaultCenter];\
	NSLog(@"%@ posting XCB" # x "Notification", self);\
	[_center postNotificationName: XCB ## x ## Notification\
	                      object: self];\
}
