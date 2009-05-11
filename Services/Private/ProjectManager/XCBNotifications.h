#import <Foundation/NSString.h>

#ifndef DEFINE_NOTIFICATION
#define DEFINE_NOTIFICATION(x) extern NSString *XCB ## x ##Notification
#endif

DEFINE_NOTIFICATION(WindowDidMap);
DEFINE_NOTIFICATION(WindowDidUnMap);
DEFINE_NOTIFICATION(WindowFrameDidChange);
