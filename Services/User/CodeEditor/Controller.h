#import <AppKit/AppKit.h>
#import <PaneKit/PaneKit.h>

@interface Controller: NSObject
{
  NSMutableArray *windows; // All open windows
  PKPreferencesController *preferencesController;
}

- (void) openInWindow: (id) sender;
- (void) openInTab: (id) sender;
- (void) newInWindow: (id) sender;
- (void) newInTab: (id) sender;
- (void) closeWindow: (id) sender;
- (void) closeTab: (id) sender;

- (void) showPreferences: (id) sender;

@end

