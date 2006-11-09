#import "PaneController.h"
#import "LogPane.h"
#import "GNUstep.h"

@implementation PaneController
- (id) initWithRegistry: (PKPaneRegistry *) r
       presentationMode: (const NSString *) mode
       owner: (id) o
{
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
         @"Log", @"identifier",
         @"Log", @"name",
         @"Log", @"path",
         [NSValue valueWithPointer: [LogPane class]], @"class",
         AUTORELEASE([[LogPane alloc] init]), @"instance", nil];
  [r addPlugin: dict];

  self = [super initWithRegistry: r
                presentationMode: mode
                owner: o];

  return self;
}

@end

