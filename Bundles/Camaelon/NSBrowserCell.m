#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"
#include "NSBezierPath+round.h"

@implementation NSBrowserCell (theme)

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{     
  NSRect        title_rect = cellFrame;
  NSImage       *image = nil;
  NSColor       *backColor;
  NSWindow      *cvWin = [controlView window];
  BOOL          showsFirstResponder;

  if (!cvWin)
    return;
      
  if (_cell.is_highlighted || _cell.state)
    {
      backColor = [self highlightColorInView: controlView];
      backColor = [NSColor colorWithCalibratedRed: 0.7 green: 0.7 blue: 0.8 alpha: 1.0];
      [backColor set];
      if (!_browsercell_is_leaf)
        image = [isa highlightedBranchImage];
    } 
  else
    { 
      backColor = [cvWin backgroundColor];
      backColor = [NSColor whiteColor];
      [backColor set];
      if (!_browsercell_is_leaf)
        image = [isa branchImage];
    }
  // Clear the background
  NSRectFill(cellFrame);

  showsFirstResponder = _cell.shows_first_responder;

  // Draw the branch image if there is one
  if (image)
    {
      NSRect image_rect;

      image_rect.origin = cellFrame.origin;
      image_rect.size = [image size];
      image_rect.origin.x += cellFrame.size.width - image_rect.size.width - 4.0;
      image_rect.origin.y
        += (cellFrame.size.height - image_rect.size.height) / 2.0;
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([controlView isFlipped])
        image_rect.origin.y += image_rect.size.height;
      [image compositeToPoint: image_rect.origin
             operation: NSCompositeSourceOver];

      title_rect.size.width -= image_rect.size.width + 8;
    }

  // Skip 2 points from the left border
  title_rect.origin.x += 2;
  title_rect.size.width -= 2;

  // Draw the body of the cell
  if ((_cell.type == NSImageCellType)
      && (_cell.is_highlighted || _cell.state)
      && _alternateImage)
    {
      // Draw the alternateImage 
      NSSize size;
      NSPoint position;

      size = [_alternateImage size];
      position.x = MAX(NSMidX(title_rect) - (size.width/2.),0.);
      position.y = MAX(NSMidY(title_rect) - (size.height/2.),0.);
      if ([controlView isFlipped])
        position.y += size.height;
      [_alternateImage compositeToPoint: position
                       operation: NSCompositeSourceOver];
    }
  else
    {
      // Draw image, or text
      _cell.shows_first_responder = NO;

      [super drawInteriorWithFrame: title_rect inView: controlView];
    }

  if (showsFirstResponder == YES)
  {
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSRect rect = NSMakeRect (cellFrame.origin.x + 1, cellFrame.origin.y + 1, cellFrame.size.width - 2, cellFrame.size.height - 2);
	[path appendBezierPathWithRoundedRectangle: rect withRadius: 4.0];
	[[NSColor colorWithCalibratedRed: 0.4 green: 0.4 blue: 0.4 alpha: 1.0] set];
	[path setLineWidth: 2];
//	[path stroke];
//    NSDottedFrameRect(cellFrame);
  }
  _cell.shows_first_responder = showsFirstResponder;
}


@end
