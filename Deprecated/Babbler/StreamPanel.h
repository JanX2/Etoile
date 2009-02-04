#import <AppKit/AppKit.h>

@interface StreamPanel: NSPanel
{
  NSWindow *window;
  NSTextField *urlField;
}

+ (StreamPanel *) streamPanel;
- (int) runModal;

- (NSURL *) URL;
- (void) okAction: (id) sender;
- (void) cancelAction: (id) sender;

@end

