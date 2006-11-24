#import <AppKit/AppKit.h>

@interface Controller: NSObject
{
  NSMutableArray *players;
}

- (void) openFile: (id) sender;
- (void) openStream: (id) sender;

@end

