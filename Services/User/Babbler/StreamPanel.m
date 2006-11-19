#import "StreamPanel.h"

static StreamPanel *sharedInstance;

@implementation StreamPanel
+ (StreamPanel *) streamPanel
{
  if (sharedInstance == nil) {
    NSRect frame = NSMakeRect(200, 200, 400, 150);
    sharedInstance = [[StreamPanel alloc] initWithContentRect: frame
                 styleMask: NSTitledWindowMask
                 backing: NSBackingStoreRetained
                 defer: NO];
  }
  return sharedInstance;
}

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
                    screen: (NSScreen*) aScreen
{
  self = [super initWithContentRect: contentRect
                styleMask: aStyle
                backing: bufferingType
                defer: NO // Always NO to have x window created now
                screen: aScreen];

  [self setDelegate: self];

  NSRect frame = contentRect;

  frame = NSMakeRect(5, contentRect.size.height-5-25, 200, 25);
  NSTextField *label = [[NSTextField alloc] initWithFrame: frame];
  [label setEditable: NO];
  [label setSelectable: NO];
  [label setBezeled: NO];
  [label setDrawsBackground: NO];
  [label setStringValue: _(@"Stream location:")];
  [[self contentView] addSubview: label];
  DESTROY(label);

  frame = NSMakeRect(5, NSMinY(frame)-5-25, contentRect.size.width-5*2, 25);
  urlField =  [[NSTextField alloc] initWithFrame: frame];
  [[self contentView] addSubview: urlField];
  
  frame = NSMakeRect(contentRect.size.width-80-5, NSMinY(frame)-5-25, 80, 25);
  NSButton *button = [[NSButton alloc] initWithFrame: frame];
  [button setTarget: self];
  [button setAction: @selector(okAction:)];
  [button setImagePosition: NSImageRight];
  [button setTitle: _(@"OK")];
  [button setImage: [NSImage imageNamed: @"common_ret"]];
  [button setAlternateImage: [NSImage imageNamed: @"common_retH"]];
  [[self contentView] addSubview: button];
  [self setDefaultButtonCell: [button cell]];
  DESTROY(button);

  frame = NSMakeRect(NSMinX(frame)-80-5, NSMinY(frame), 80, 25);
  button = [[NSButton alloc] initWithFrame: frame];
  [button setTarget: self];
  [button setAction: @selector(cancelAction:)];
  [button setTitle: _(@"Cancel")];
  [[self contentView] addSubview: button];
  DESTROY(button);

  [self setReleasedWhenClosed: NO];
  [self setTitle: _(@"Open stream")];

  return self;
}

- (int) runModal
{
  return [NSApp runModalForWindow: self];
}

- (void) okAction: (id) sender
{
  [self close];
  [NSApp stopModalWithCode: NSOKButton];
}

- (void) cancelAction: (id) sender
{
  [self close];
  [NSApp stopModalWithCode: NSCancelButton];
}

- (NSURL *) URL
{
  return [NSURL URLWithString: [urlField stringValue]];
}

@end
