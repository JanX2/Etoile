#import <Foundation/NSString.h>

#ifndef DEFINE_NOTIFICATION
#define DEFINE_NOTIFICATION(x) extern NSString *PM ## x ##Notification
#endif

DEFINE_NOTIFICATION(CompositeWindowTransformDidChange);

#define PMNOTIFY(x) \
{\
	NSNotificationCenter *_center = [NSNotificationCenter defaultCenter];\
	NSLog(@"%@ posting PM" # x "Notification", self);\
	[_center postNotificationName: PM ## x ## Notification\
	                       object: self];\
}
#undef DEFINE_NOTIFICATION
