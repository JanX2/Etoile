#import <AppKit/AppKit.h>
#import <OSObject.h>

#define CELL_SIZE 70

@interface OSDistributedCell: NSActionCell
{
  /* OSDistributedView is flipped. So it is top-left point.
     It is used by view, not itself. */
  NSPoint origin;
  id <OSObject> object;

  NSSize previewSize;
  NSSize textSize;
  NSAttributedString *title;

  BOOL isDropTarget;
}

- (void) setOrigin: (NSPoint) point;
- (NSPoint) origin;

- (void) setObject: (id <OSObject>) object;
- (id <OSObject>) object;

/* During the drop, this one will be set in order to change visualization.
   Only one in the view can have this set. */
- (void) setDropTarget: (BOOL) flag;
- (BOOL) isDropTarget;

@end

