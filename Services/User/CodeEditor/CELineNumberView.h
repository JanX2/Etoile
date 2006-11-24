#import <AppKit/AppKit.h>

@class CETextView;

/* This is added on top of CETextView */
@interface CELineNumberView: NSView
{
  NSMutableString *numberString;
  NSDictionary *attributes;
  CETextView *textView; // Not retained 
  NSFont *font;
  NSColor *fontColor;
  NSColor *backgroundColor;
}

- (void) updateLineNumber: (id) sender;
- (void) setTextView: (CETextView *) textView;

@end

