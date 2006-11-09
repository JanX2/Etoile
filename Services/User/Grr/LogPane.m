#import "LogPane.h"
#import "GNUstep.h"
#import "Global.h"

@implementation LogPane
- (void) notificationReceived: (NSNotification *) not
{
  NSString *s = [NSString stringWithFormat: @"%@\n%@\n%@\n%@\n\n", [NSDate date], [not name], [not object], [not userInfo]];
  [[textView textStorage] appendAttributedString: AUTORELEASE([[NSAttributedString alloc] initWithString: s])];
}

- (void) clearButtonAction: (id) sender
{
  [textView setString: @""];
}

- (id) init
{
  self = [super init];

  NSRect rect = NSMakeRect(0, 0, 400, 400);
  _mainView = [[NSView alloc] initWithFrame: rect];

  rect.origin.y = 30;
  rect.size.height -= rect.origin.y;
  NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame: rect];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setHasHorizontalScroller: YES];

  rect.size = [scrollView contentSize];
  textView = [[NSTextView alloc] initWithFrame: rect];
  [textView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

  [scrollView setDocumentView: textView];
  [_mainView addSubview: scrollView];
  RELEASE(scrollView);

  rect = NSMakeRect(NSMaxX(rect)-80, 5, 70, 25);
  NSButton *button = [[NSButton alloc] initWithFrame: rect];
  [button setTitle: _(@"Clear")];
  [button setTarget: self];
  [button setAction: @selector(clearButtonAction:)];
  [button setBezelStyle: NSRoundedBezelStyle];
  [_mainView addSubview: button];
  RELEASE(button);

  [[NSNotificationCenter defaultCenter] addObserver: self
                        selector: @selector(notificationReceived:)
                        name: RSSReaderLogNotification
                        object: nil];

  return self;
}
@end

