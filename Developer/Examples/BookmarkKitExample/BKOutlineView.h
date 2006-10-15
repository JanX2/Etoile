#import <AppKit/AppKit.h>

@interface BKOutlineView: NSOutlineView
{
  BOOL activeView; // decide whether this view is active
}

- (BOOL) active;

@end

