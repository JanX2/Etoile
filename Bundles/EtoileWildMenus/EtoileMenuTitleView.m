
#import "EtoileMenuTitleView.h"

#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSWindow.h>

#import <Foundation/NSBundle.h>

#import "EtoileMenuUtilities.h"

@implementation EtoileMenuTitleView

static NSImage * MenuTitleFiller = nil;
static float MenuTitleFillerWidth = 0;

+ (void) initialize
{
  if (self == [EtoileMenuTitleView class])
    {
      ASSIGN(MenuTitleFiller,
        FindImageInBundleOfClass(self, @"MenuTitleFiller"));

      MenuTitleFillerWidth = [MenuTitleFiller size].width;
       // sanity check in case the image could not be loaded
      if (MenuTitleFillerWidth == 0)
        {
          MenuTitleFillerWidth = 100;
        }
    }
}

+ (float) height
{
  static float height = 0.0;

  if (height == 0.0)
    {
      NSFont *font = [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]];

      /* Minimum title height is 16 */
      height = ([font boundingRectForFont].size.height) + 4;
      if (height < 16)
        {
          height = 16;
        }
    }

  return height;
}

- init
{
  if ((self = [super init]) != nil)
    {
      NSFont * f = [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]];

      fontHeight = [f defaultLineHeightForFont];

      titleDrawingAttributes = [[NSDictionary alloc]
        initWithObjectsAndKeys:
        f, NSFontAttributeName,
        [NSColor blackColor], NSForegroundColorAttributeName,
        nil];
    }

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(titleDrawingAttributes);

  [super dealloc];
}

- (void) drawRect: (NSRect) r
{
  float x;
  NSFont * font;
  float height;
  NSRect myFrame = [self frame];
  NSRect rect;

  // paint the tiled background
  for (x = NSMinX(r); x < NSMaxX(r); x += MenuTitleFillerWidth)
    {
      [MenuTitleFiller compositeToPoint: NSMakePoint(x, 0)
                              operation: NSCompositeCopy];
    }

  font = [titleDrawingAttributes objectForKey: NSFontAttributeName];
  height = [font defaultLineHeightForFont];
  rect = NSMakeRect(4, (NSHeight(myFrame) - height) / 2,
                    NSWidth(myFrame), height);
  [[[self owner] title] drawInRect: rect
                    withAttributes: titleDrawingAttributes];

  myFrame.origin = NSZeroPoint;
  [[NSColor blackColor] set];
  NSFrameRect(myFrame);
}

- (void) addCloseButtonWithAction: (SEL)closeAction
{
  if (closeButton == nil)
    {
      NSImage *closeImage = FindImageInBundle(self, @"EtoileMenuClose");
      NSImage *closeHImage = FindImageInBundle(self, @"EtoileMenuCloseH");

      NSSize viewSize;
      NSSize buttonSize;
      
      closeButton = [[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 12, 12)];
      [closeButton setRefusesFirstResponder: YES];
      [closeButton setImagePosition: NSImageOnly];
      [closeButton setBordered: NO];
      [closeButton setButtonType: NSMomentaryChangeButton];
      [closeButton setImage: closeImage];
      [closeButton setAlternateImage: closeHImage];
      [closeButton setTarget: [self owner]];
      [closeButton setAction: closeAction];

      viewSize = [self frame].size;
      buttonSize = [closeButton frame].size;

      NSLog(@"viewSize: %@, buttonSize: %@", NSStringFromSize(viewSize),
        NSStringFromSize(buttonSize));

      // Update location
      [closeButton setFrameOrigin:
        NSMakePoint (viewSize.width - buttonSize.width - 4,
                     (viewSize.height - buttonSize.height) / 2)];

      [closeButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
    }

  if ([closeButton superview] == nil)
    {
      [self addSubview: closeButton];
      RELEASE (closeButton);
      [self setNeedsDisplay: YES];
    }
}

@end
