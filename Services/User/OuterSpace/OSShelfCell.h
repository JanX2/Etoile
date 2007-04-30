#import <AppKit/AppKit.h>

@interface OSShelfCell: NSButtonCell
{
  id object;
}

- (void) setObject: (id) object;
- (id) object;

@end

