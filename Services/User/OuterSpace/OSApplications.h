#import "OSVirtualNode.h"

/* This is a virtual node to display all installed applications.
   It supports GNUstep applications for now */
@interface OSApplications: OSVirtualNode
{
  NSMutableArray *apps;
}
@end

