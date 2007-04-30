#import <AppKit/AppKit.h>
#import "OSObject.h"

@class OSNode, OSApplications, OSTrashCan;

/* OSObjectFactory take a path and generate an autoreleased OSObject */
@interface OSObjectFactory: NSObject
{
  NSMutableArray *prototypes; /* We keep a copy of prototype of OSObject */
}

+ (OSObjectFactory *) defaultFactory;
- (id <OSObject>) objectAtPath: (NSString *) path;

/* For convenience */
- (OSNode *) homeObject; /* User home. OSNode. */
- (OSApplications *) applications; /* All applications. OSVirtualNode. */
- (OSTrashCan *) trashCan; /* Trash can. OSNode. */

@end

