
#import "NSMenuItemCell+Hackery.h"

#import <AppKit/NSMenuView.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/PSOperators.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSParagraphStyle.h>

#import "EtoileSeparatorMenuItem.h"

@implementation NSMenuItemCell (EtoileMenusHackery)

#if 0
- (void) drawInteriorWithFrame: (NSRect) cellFrame
                        inView: (NSView*) controlView
{
  NSLog(@"WildMenus - NSMenuItemCell %@ -drawInteriorWithFrame:inView:", [[self menuItem] title]);

  if ([_menuItem isKindOfClass: [EtoileSeparatorMenuItem class]])
    {
      [self drawSeparatorItemWithFrame: cellFrame inView: controlView];
    }
  else
    {
      unsigned  mask;

      // Transparent buttons never draw
      if (_buttoncell_is_transparent)
        return;

      cellFrame = [self drawingRectForBounds: cellFrame];

      if (_cell.is_highlighted)
        {
          mask = _highlightsByMask;

          if (_cell.state)
            {
              mask &= ~_showAltStateMask;
            }
        }
      else if (_cell.state)
        {
          mask = _showAltStateMask;
        }
      else
        {
          mask = NSNoCellMask;
        }

      {
        NSColor * backgroundColor = [NSColor colorWithCalibratedWhite: 0.9
                                                                alpha: 1.0];

        [backgroundColor set];
        NSRectFill(cellFrame);
      }

      // pushed in buttons contents are displaced to the bottom right 1px
      if (_cell.is_bordered && (mask & NSPushInCellMask))
        {
          cellFrame = NSOffsetRect(cellFrame, 1,
                                   [controlView isFlipped] ? 1 : -1);
        }

      /*
       * Determine the background color and cache it in an ivar so that the
       * low-level drawing methods don't need to do it again.
       */
      if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
        {
          NSColor * backgroundColor;

          backgroundColor = [NSColor colorWithCalibratedRed: 0.0
                                                      green: 0.0
                                                       blue: 1
                                                      alpha: 0.3];

          [backgroundColor set];
          NSRectFill(cellFrame);
        }
      /*
       * Determine the image and the title that will be
       * displayed. If the NSContentsCellMask is set the
       * image and title are swapped only if state is 1 or
       * if highlighting is set (when a button is pushed it's
       * content is changed to the face of reversed state).
       * The results are saved in two ivars for use in other
       * drawing methods.
       */
      else if (mask & NSContentsCellMask)
        {
          _imageToDisplay = _altImage;
          if (!_imageToDisplay)
            {
              _imageToDisplay = [_menuItem image];
            }
          _titleToDisplay = _altContents;

          if (_titleToDisplay == nil || [_titleToDisplay isEqual: @""])
            {
              _titleToDisplay = [_menuItem title];
            }
        }
      else
        {
          _imageToDisplay = [_menuItem image];
          _titleToDisplay = [_menuItem title];
        }

      if (_imageToDisplay)
        {
          _imageWidth = [_imageToDisplay size].width;
        }

      // Draw the state image
      if (_stateImageWidth > 0)
        {
          [self drawStateImageWithFrame: cellFrame inView: controlView];
        }

      // Draw the image
      if (_imageWidth > 0)
        {
          [self drawImageWithFrame: cellFrame inView: controlView];
        }

      // Draw the title
      if (_titleWidth > 0)
        {
          [self drawTitleWithFrame: cellFrame inView: controlView];
        }

      // Draw the key equivalent
      if (_keyEquivalentWidth > 0)
        {
          [self drawKeyEquivalentWithFrame: cellFrame inView: controlView];
        }
    }
}
#endif

/*
- (void) drawTitleWithFrame:(NSRect)cellFrame
                    inView:(NSView *)controlView
{
  if ([_menuView isHorizontal] == YES)
    {
      id value = [NSMutableParagraphStyle defaultParagraphStyle];
      NSDictionary *attr;
      NSRect cf = [self titleRectForBounds: cellFrame];
      NSColor * color;

      if (!_imageWidth)
        [value setAlignment: NSCenterTextAlignment];

      if ([self isHighlighted])
        {
          color = [NSColor whiteColor];
        }
      else
        {
          color = [NSColor controlTextColor];
        }

      attr = [[NSDictionary alloc] initWithObjectsAndKeys:
        value, NSParagraphStyleAttributeName,
        _font, NSFontAttributeName,
        color, NSForegroundColorAttributeName,
        nil];

      if ([_menuItem isEnabled])
        _cell.is_disabled = NO;
      else
        _cell.is_disabled = YES;

      [[_menuItem title] drawInRect: cf withAttributes: attr];

      RELEASE(attr);
    }
  else
    {
      [self _drawText: [_menuItem title]
              inFrame: [self titleRectForBounds: cellFrame]];
    }
}*/

- (void) drawSeparatorItemWithFrame:(NSRect)cellFrame
                            inView:(NSView *)controlView
{
  [[NSColor lightGrayColor] set];
  PSmoveto(NSMinX(cellFrame) + 2, NSMidY(cellFrame));
  PSrlineto(NSWidth(cellFrame) - 4, 0);
  PSstroke();

  [[NSColor whiteColor] set];
  PSmoveto(NSMinX(cellFrame) + 2, NSMidY(cellFrame) - 1);
  PSrlineto(NSWidth(cellFrame) - 4, 0);
  PSstroke();
}

@end
