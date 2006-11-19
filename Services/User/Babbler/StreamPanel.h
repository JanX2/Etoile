#import <AppKit/AppKit.h>

@interface StreamPanel: NSPanel
{
  NSTextField *urlField;
}

+ (StreamPanel *) streamPanel;
- (int) runModal;

- (NSURL *) URL;

@end

