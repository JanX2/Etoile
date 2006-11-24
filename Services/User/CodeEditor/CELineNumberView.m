#import "CELineNumberView.h"
#import "GNUstep.h"

@implementation CELineNumberView
- (BOOL) isFlipped
{
  return YES;
}

- (void) drawRect: (NSRect) rect
{
  [self lockFocus];
  [super drawRect: rect];
  [backgroundColor set];
  [NSBezierPath fillRect: rect];
  [fontColor set];
  [numberString drawAtPoint: NSMakePoint(5, 0)
                withAttributes: attributes];
  [self unlockFocus];
}

- (void) updateLineNumber: (id) sender
{
  NSLayoutManager *layoutManager = [textView layoutManager];
  unsigned int numberOfGlyphs = [layoutManager numberOfGlyphs];
  NSRange range = NSMakeRange(0, 1);;
  unsigned int index = 0, total = 1;
  while (NSMaxRange(range) < numberOfGlyphs) {
    [layoutManager lineFragmentRectForGlyphAtIndex: index effectiveRange: &range];
    index = NSMaxRange(range);
    [numberString appendFormat: @"%d\n", total++];
  }
}

- (void) setTextView: (CETextView *) tv
{
  // Not retained.
  textView = tv;
  ASSIGN(font, [textView font]);
  ASSIGN(attributes, ([NSDictionary dictionaryWithObjectsAndKeys: 
                        fontColor, NSForegroundColorAttributeName,
                         font, NSFontAttributeName,
                        nil]));
  [self updateLineNumber: self];
}

- (id) initWithFrame: (NSRect) frame
{
  self = [super initWithFrame: frame];
  ASSIGN(backgroundColor, [NSColor lightGrayColor]);
  ASSIGN(fontColor, [NSColor blackColor]);
  numberString = [[NSMutableString alloc] init];
  
  return self;
}

- (void) dealloc
{
  DESTROY(backgroundColor);
  DESTROY(font);
  DESTROY(numberString);
  DESTROY(attributes);
  [super dealloc];
}
@end
