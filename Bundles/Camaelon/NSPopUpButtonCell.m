#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"

@interface NSPopUpButtonCell (theme)
@end

@implementation NSPopUpButtonCell (theme)
- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  // Save last view drawn to
  if (_control_view != controlView)
    _control_view = controlView;

  // transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  if ((_cell.is_bordered) &&
      (!_shows_border_only_while_mouse_inside || _mouse_inside))
  {
	switch ([self bezelStyle])
	{
		case NSRoundedBezelStyle:
			[THEME drawPopupButton: cellFrame inView: controlView];
			break;
		default:
			[THEME drawButton: cellFrame inView: controlView
				style: [self bezelStyle] highlighted: _cell.is_highlighted];
			break;
	}
  }
  else if (_cell.is_highlighted)
  {
  	NSColor	*backgroundColor = nil;
	backgroundColor = [NSColor selectedControlColor];
      	if (backgroundColor != nil) 
	{
	  [backgroundColor set];
	  NSRectFill (cellFrame);
	}
  }

  [self drawInteriorWithFrame: cellFrame inView: controlView];

/*
  if (_cell.shows_first_responder
	  && [[controlView window] firstResponder] == controlView)
  {
	[THEME drawFocusFrame: cellFrame];
  }
*/
}
- (void) drawInteriorWithFrame: (NSRect)cellFrame
                        inView: (NSView*)controlView
{
  BOOL new = NO;

  if ([self menuItem] == nil)
    {
      NSMenuItem *anItem;

      /* 
       * Create a temporary NSMenuItemCell to at least draw our control,
       * if items array is empty.
       */
      anItem = [NSMenuItem new];
      [anItem setTitle: [self title]];
      /* We need this menu item because NSMenuItemCell gets its contents 
       * from the menuItem not from what is set in the cell */
      [self setMenuItem: anItem];
      RELEASE(anItem);
      new = YES;
    }
  
//  [THEME drawButton: cellFrame inView: controlView highlighted: NO];


  /* We need to calc our size to get images placed correctly */
  [self calcSize];
  [super drawInteriorWithFrame: cellFrame inView: controlView];

/*
  if (_cell.shows_first_responder)
    {
      cellFrame = [self drawingRectForBounds: cellFrame];
      //NSDottedFrameRect(cellFrame);
	[THEME drawFocusFrame: cellFrame];
    }
*/
  /* Unset the item to restore balance if a new was created */
  if (new)
    {
      [self setMenuItem: nil];
    }

}

@end
