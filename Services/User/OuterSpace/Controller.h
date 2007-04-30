#import <AppKit/AppKit.h>
#import "OSObject.h"

@interface Controller : NSObject
{
}

/* If object has children, show them.
   If object has no children, show its parent based on path. */
- (void) showObject: (id <OSObject>) object;

@end

