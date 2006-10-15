#import <AppKit/AppKit.h>

@interface BKTableView: NSTableView
{
  BOOL activeView;
}

- (BOOL) active;
@end

