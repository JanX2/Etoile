#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"
#include "GSDrawFunctions.h"

@implementation NSScrollView (theme)

- (void) drawRect: (NSRect)rect
{
  NSRectClip(rect);
  [[_window backgroundColor] set];
  [[NSColor blueColor] set];
  [[NSColor blueColor] set];
  [[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.6 alpha: 1.0] set];
  NSRectFill(rect);
/*
NSRect vS = [_vertScroller frame];
[_vertScroller setFrame: NSMakeRect (vS.origin.x-1, vS.origin.y-1, vS.size.width+2,vS.size.height+2)];
*/
 [self setBackgroundColor: [NSColor rowBackgroundColor]];
 id documentView = [self documentView];

 /*
 if ([documentView respondsToSelector: @selector(setBackgroundColor:)])
 {
 	[[self documentView] setBackgroundColor: [NSColor rowBackgroundColor]];
 }
 */
  //NSGraphicsContext *ctxt = GSCurrentContext();

  switch (_borderType)
    {
//      case NSNoBorder:

  //      break;

//      case NSLineBorder:
//        [[NSColor controlDarkShadowColor] set];
//        NSFrameRect(_bounds);
//        break;

 //     case NSBezelBorder:
 //       NSDrawGrayBezel(_bounds, rect);
 //       break;

 //     case NSGrooveBorder:
 //       NSDrawGroove(_bounds, rect);
//        break;

//	default:


    }

	NSBezierPath* path = [NSBezierPath bezierPath];
	NSRect mrect = NSMakeRect (rect.origin.x + 1, rect.origin.y + 1, rect.size.width - 2, rect.size.height - 2);
	[path appendBezierPathWithRect: rect];
/*	if ([self hasHorizontalScroller] && [self hasVerticalScroller])
	{
        	//[path appendBezierPathWithLeftAndBottomRoundedCorners: mrect withRadius: 8.0];
		if ([self isFlipped])
		{
        		[path appendBezierPathWithTopRoundedCorners: mrect withRadius: 8.0];	
		}
		else
		{	
        		[path appendBezierPathWithBottomRoundedCorners: mrect withRadius: 8.0];	
		}
	}
	else if ([self hasHorizontalScroller])
	{
		if ([self isFlipped])
		{
        		[path appendBezierPathWithTopRoundedCorners: mrect withRadius: 8.0];	
		}
		else
		{	
        		[path appendBezierPathWithBottomRoundedCorners: mrect withRadius: 8.0];	
		}
	}
	else if ([self hasVerticalScroller])
	{
        	[path appendBezierPathWithLeftRoundedCorners: mrect withRadius: 8.0];
	}
*/
        //[path appendBezierPathWithLeftRoundedCorners: mrect withRadius: 8.0];
	//[path appendBezierPathWithRoundedRectangle: mrect withRadius: 8.0];
	/*
	[[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.6 alpha: 1.0] set];
	[path setLineWidth: 0];
	[path stroke];
	*/
	[GSDrawFunctions drawScrollViewFrame: rect on: self];
	

/*
  [[NSColor controlDarkShadowColor] set];
  DPSsetlinewidth(ctxt, 1);

  if (_hasVertScroller)
    {
      DPSmoveto(ctxt, [_vertScroller frame].origin.x + [NSScroller scrollerWidth],
                [_vertScroller frame].origin.y - 1);
      DPSrlineto(ctxt, 0, [_vertScroller frame].size.height + 1);
      DPSstroke(ctxt);
    }

  if (_hasHorizScroller)
    {
      float ypos;
      float scrollerY = [_horizScroller frame].origin.y;

      if (_rFlags.flipped_view)
        {
          ypos = scrollerY - 1;
        }
      else
        {
          ypos = scrollerY + [NSScroller scrollerWidth] + 1;
        }

      DPSmoveto(ctxt, [_horizScroller frame].origin.x - 1, ypos);
      DPSrlineto(ctxt, [_horizScroller frame].size.width + 1, 0);
      DPSstroke(ctxt);
    }
*/
}

- (void) tile
{
  NSRect headerRect, contentRect;
  NSSize border = _sizeForBorderType(_borderType);
  NSRectEdge bottomEdge, topEdge;
  float headerViewHeight = 0;

  /* Determine edge positions.  */
  if (_rFlags.flipped_view)
    {
      topEdge = NSMinYEdge;
      bottomEdge = NSMaxYEdge;
    }
  else
    {
      topEdge = NSMaxYEdge;
      bottomEdge = NSMinYEdge;
    }


  /* Prepare the contentRect by the insetting the borders.  */
  contentRect = NSInsetRect (_bounds, border.width, border.height);
  contentRect = NSInsetRect (_bounds,1.0,1.0);
  
  [self _synchronizeHeaderAndCornerView];
  
  /* First, allocate vertical space for the headerView / cornerView
     (but - NB - the headerView needs to be placed above the clipview
     later on, we can't place it now).  */

  if (_hasHeaderView == YES)
    {
      headerViewHeight = [[_headerClipView documentView] frame].size.height;
    }

  if (_hasCornerView == YES)
    {
      if (headerViewHeight == 0)
	{
	  headerViewHeight = [_cornerView frame].size.height;
	}
    }

  /* Remove the vertical slice used by the header/corner view.  Save
     the height and y position of headerRect for later reuse.  */
  NSDivideRect (contentRect, &headerRect, &contentRect, headerViewHeight, 
		topEdge);

  /* Ok - now go on with drawing the actual scrollview in the
     remaining space.  Just consider contentRect to be the area in
     which we draw, ignoring header/corner view.  */

      float scrollerWidth =  [NSScroller scrollerWidth];

  /* Prepare the vertical scroller.  */
  if (_hasVertScroller)
    {
      NSRect vertScrollerRect;


      NSDivideRect (contentRect, &vertScrollerRect, &contentRect, 
		    scrollerWidth, NSMinXEdge);

      [_vertScroller setFrame: vertScrollerRect];

      /* Substract 1 for the line that separates the vertical scroller
       * from the clip view (and eventually the horizontal scroller).  */
      NSDivideRect (contentRect, NULL, &contentRect, 1, NSMinXEdge);
    }

  /* Prepare the horizontal scroller.  */
  if (_hasHorizScroller)
    {
      NSRect horizScrollerRect;
      
      NSDivideRect (contentRect, &horizScrollerRect, &contentRect, 
		    scrollerWidth, bottomEdge);

      [_horizScroller setFrame: horizScrollerRect];

      /* Substract 1 for the width for the line that separates the
       * horizontal scroller from the clip view.  */
      NSDivideRect (contentRect, NULL, &contentRect, 1, bottomEdge);
    }

  /* Now place and size the header view to be exactly above the
     resulting clipview.  */
  if (_hasHeaderView)
    {
      NSRect rect = headerRect;

      rect.origin.x = contentRect.origin.x;
      rect.size.width = contentRect.size.width;

      [_headerClipView setFrame: rect];
    }

  /* Now place the corner view.  */
  if (_hasCornerView)
    {
      [_cornerView setFrameOrigin: headerRect.origin];
    }

  /* Now place the rulers.  */
  if (_rulersVisible)
    {
      if (_hasHorizRuler)
	{
	  NSRect horizRulerRect;
	  
	  NSDivideRect (contentRect, &horizRulerRect, &contentRect,
			[_horizRuler requiredThickness], topEdge);
	  [_horizRuler setFrame: horizRulerRect];
	}

      if (_hasVertRuler)
	{
	  NSRect vertRulerRect;
	  
	  NSDivideRect (contentRect, &vertRulerRect, &contentRect,
			[_vertRuler requiredThickness], NSMinXEdge);
	  [_vertRuler setFrame: vertRulerRect];
	}
    }

  [_contentView setFrame: contentRect];
  [self setNeedsDisplay: YES];
}



@end
