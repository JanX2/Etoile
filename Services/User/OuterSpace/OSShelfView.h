#import <AppKit/AppKit.h>
#import "OSObject.h"

@interface OSShelfView: NSControl
{
  NSMutableArray *cells;
  id delegate;
}
/* Take OSObject. Use NSNull as separator. */
- (int) numberOfObjects;
- (void) addObject: (id) object;
- (void) insertObject: (id) object atIndex: (int) index;
- (void) removeObjectAtIndex: (int) index;
- (id) objectAtIndex: (int) index;

- (void) setDelegate: (id) delegate;
- (id) delegate;

@end

@interface NSObject (OSShelfViewDelegate)
- (void) shelfView: (OSShelfView *) view objectClicked: (id <OSObject>) object;
@end


