
#import "MenuBarView.h"

#import <AppKit/NSImage.h>

@implementation MenuBarView

static NSImage * filler = nil,
               * leftEdge = nil,
               * rightEdge = nil,
               * etoileLogo = nil;

+ (void) initialize
{
  if (self == [MenuBarView class])
    {
      ASSIGN(filler, [NSImage imageNamed: @"MenuBarFiller"]);
      ASSIGN(leftEdge, [NSImage imageNamed: @"MenuBarLeftEdge"]);
      ASSIGN(rightEdge, [NSImage imageNamed: @"MenuBarRightEdge"]);
    }
}

- (BOOL) drawsCorners
{
  return drawsCorners;
}

- (void) setDrawsCorners: (BOOL) flag
{
  if (drawsCorners != flag)
    {
      drawsCorners = flag; 
      [self setNeedsDisplay: YES];
    }
}

- (void) drawRect: (NSRect) r
{
  float offset;
  NSSize size;

  size = [filler size];
  for (offset = NSMinX(r); offset < NSMaxX(r); offset += size.width)
    {
      [filler compositeToPoint: NSMakePoint(offset, 0)
                     operation: NSCompositeCopy];
    }

  if (drawsCorners)
    {
      NSPoint p;

      size = [leftEdge size];
      if (NSMinX(r) <= size.width)
        {
          [leftEdge compositeToPoint: NSZeroPoint operation: NSCompositeCopy];
        }

      size = [rightEdge size];
      p = NSMakePoint(NSMaxX([self frame]) - size.width, 0);
      [rightEdge compositeToPoint: p operation: NSCompositeCopy];
    }
}

@end
