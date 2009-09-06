
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"
#include "ImageProvider.h"

@implementation NSTabView (theme)

- (void) drawRect: (NSRect)rect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  int			howMany = [_items count];
  int			i = 0;
  NSRect		previousRect = NSZeroRect;
  int			previousState = 0;
  NSRect		aRect = _bounds;

  DPSgsave(ctxt);
  NSImage* img = [NSImage imageNamed: @"Tabs/Tabs-selected-fill.tiff"];

  switch (_type)
    {
      default:
      case NSTopTabsBezelBorder: 
	aRect.size.height -= [img size].height;
	//aRect.size.height -= 16;
//	aRect.origin.y += 1;
	[THEME drawTabFrame: aRect on: self];
	break;

      case NSBottomTabsBezelBorder: 
	aRect.size.height -= 16;
	aRect.origin.y += 16;
	[THEME drawTabFrame: aRect on: self];
	aRect.origin.y -= 16;
	break;

      case NSNoTabsBezelBorder: 
	[THEME drawTabFrame: aRect on: self];
	break;

      case NSNoTabsLineBorder: 
	[[NSColor controlDarkShadowColor] set];
	NSFrameRect(aRect);
	break;

      case NSNoTabsNoBorder: 
	break;
    }

  if (!_selected)
    [self selectFirstTabViewItem: nil];

  if (_type == NSNoTabsBezelBorder || _type == NSNoTabsLineBorder)
    {
      DPSgrestore(ctxt);
      return;
    }

  if (_type == NSBottomTabsBezelBorder)
    {
      for (i = 0; i < howMany; i++) 
	{
	  // where da tab be at?
	  NSSize	s;
	  NSRect	r;
	  NSPoint	iP;
	  NSTabViewItem *anItem = [_items objectAtIndex: i];
	  NSTabState	itemState;

	  itemState = [anItem tabState];

	  s = [anItem sizeOfLabel: NO];

	  if (i == 0)
	    {
	      int iFlex = 0;
	      iP.x = aRect.origin.x;
	      iP.y = aRect.origin.y;

	      if (itemState == NSSelectedTab)
		{
		  iP.y += 1;
		  [[NSImage imageNamed: @"common_TabDownSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		  iFlex = 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
		  iP.y += 1;
		  [[NSImage imageNamed: @"common_TabDownUnSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		}
	      else
		NSDebugLLog(@"Theme", @"Not finished yet. Luff ya.\n");

	      r.origin.x = aRect.origin.x + 13;
	      r.origin.y = aRect.origin.y + 2;
	      r.size.width = s.width;
	      r.size.height = 15 + iFlex;

	      DPSsetlinewidth(ctxt,2);
	      DPSsetgray(ctxt, NSWhite);
  	      [[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
	      DPSmoveto(ctxt, r.origin.x, r.origin.y-1);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      

	      [anItem drawLabel: NO inRect: r];

	      previousRect = r;
	      previousState = itemState;
	    }
	  else
	    {
	      int	iFlex = 0;

	      iP.x = previousRect.origin.x + previousRect.size.width;
	      iP.y = aRect.origin.y;

	      if (itemState == NSSelectedTab) 
		{
		  iP.y += 1;
		  iFlex = 1;
		  [[NSImage imageNamed:
		    @"common_TabDownUnSelectedToSelectedJunction.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
		  if (previousState == NSSelectedTab)
		    {
		      iP.y += 1;
		      [[NSImage imageNamed:
			@"common_TabDownSelectedToUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      iP.y -= 1;
		      iFlex = -1;
		    }
		  else
		    {
		      //		    iP.y += 1;
		      [[NSImage imageNamed:
			@"common_TabDownUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      //iP.y -= 1;
		      iFlex = -1;
		    }
		} 
	      else
		NSDebugLLog(@"Theme", @"Not finished yet. Luff ya.\n");
	      
	      r.origin.x = iP.x + 13;
	      r.origin.y = aRect.origin.y + 2;
	      r.size.width = s.width;
	      r.size.height = 15 + iFlex; // was 15

	      iFlex = 0;

	      DPSsetlinewidth(ctxt,2);
	      DPSsetgray(ctxt, NSWhite);
  	      [[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
	      DPSmoveto(ctxt, r.origin.x, r.origin.y - 1);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      

	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }  

	  if (i == howMany-1)
	    {
	      iP.x += s.width + 13;

	      if ([anItem tabState] == NSSelectedTab)
		[[NSImage imageNamed: @"common_TabDownSelectedRight.tiff"]
		  compositeToPoint: iP operation: NSCompositeSourceOver];
	      else if ([anItem tabState] == NSBackgroundTab)
		{
		  //		  iP.y += 1;
		  [[NSImage imageNamed: @"common_TabDownUnSelectedRight.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  //		  iP.y -= 1;
		}
	      else
		NSDebugLLog(@"Theme", @"Not finished yet. Luff ya.\n");
	    }
	}
    }
  else if (_type == NSTopTabsBezelBorder)
    {
      for (i = 0; i < howMany; i++) 
	{
	  // where da tab be at?
	  NSSize s;
	  NSRect r;
	  NSPoint iP;
	  NSTabViewItem *anItem = [_items objectAtIndex: i];
	  NSTabState itemState;
	  
	  itemState = [anItem tabState];
	  
	  s = [anItem sizeOfLabel: NO];
	
	  NSImage* img = [ImageProvider TabsSelectedLeft];
	  iP.y = aRect.size.height - [[NSImage imageNamed: @"Tabs/Tabs-panebar-fill.tiff"] size].height;
	  
	  if (i == 0)
	    {
	      iP.x = aRect.origin.x;
	      
	      if (itemState == NSSelectedTab)
		{
	//	  iP.y -= 1;
		  [[NSImage imageNamed: @"common_TabSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else if (itemState == NSBackgroundTab)
		[[NSImage imageNamed: @"common_TabUnSelectedLeft.tiff"]
		  compositeToPoint: iP operation: NSCompositeSourceOver];
	      else
		NSDebugLLog(@"Theme", @"Not finished yet. Luff ya.\n");


		r.origin.x = aRect.origin.x + [img size].width;
		r.origin.y = aRect.origin.y + aRect.size.height;
		r.size.width = s.width;
		r.size.height = [img size].height;
		
	//      r.origin.x = aRect.origin.x + 13;
	//      r.origin.y = aRect.size.height;
	//      r.size.width = s.width;
	//      r.size.height = 15;
	      
	      DPSsetlinewidth(ctxt,2);
	      DPSsetgray(ctxt, NSWhite);
  	      [[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];

	      DPSmoveto(ctxt, r.origin.x, r.origin.y+16);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      
	      
	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }
	  else
	    {
	      iP.x = previousRect.origin.x + previousRect.size.width;

	      NSImage* junction = nil;

	      	if (itemState == NSSelectedTab)
	      	{
			junction = [NSImage imageNamed: @"common_TabUnSelectToSelectedJunction.tiff"];
		}
		else if (itemState == NSBackgroundTab)
		{
			if (previousState == NSSelectedTab)
			{
				junction = [NSImage imageNamed: @"common_TabSelectedToUnSelectedJunction.tiff"];
			}
			else
			{
				junction = [NSImage imageNamed: @"common_TabUnSelectedJunction.tiff"];
			}
		}
		
		[junction compositeToPoint: iP operation: NSCompositeSourceOver];

		r.origin.x = iP.x + [junction size].width;
		r.size.height = [img size].height;
	 //     r.origin.x = iP.x + 13;
	      r.origin.y = aRect.size.height;
	      r.size.width = s.width;
	   //   r.size.height = 15;

	      DPSsetlinewidth(ctxt,2);
	      DPSsetgray(ctxt, NSWhite);
  	      [[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
	      DPSmoveto(ctxt, r.origin.x, r.origin.y+16);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      
	      
	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }  

	  if (i == howMany-1)
	    {
	      //iP.x += s.width + 13;
	      //NSImage* img = [ImageProvider TabsSelectedRight];
	      //iP.x += s.width + [img size].width + 40;
	      iP.x = previousRect.origin.x + s.width;
	    
	      if ([anItem tabState] == NSSelectedTab)
		[[NSImage imageNamed: @"common_TabSelectedRight.tiff"]
		compositeToPoint: iP operation: NSCompositeSourceOver];
	      else if ([anItem tabState] == NSBackgroundTab)
		[[NSImage imageNamed: @"common_TabUnSelectedRight.tiff"]
		compositeToPoint: iP operation: NSCompositeSourceOver];
	      else
		NSDebugLLog(@"Theme", @"Not finished yet. Luff ya.\n");
	    }
	}
    }

  DPSgrestore(ctxt);
}

- (NSRect) contentRect
{
  NSRect cRect = _bounds;

  if (_type == NSTopTabsBezelBorder)
    {
	  NSImage* img = [ImageProvider TabsSelectedLeft];
	  NSImage* bar = [NSImage imageNamed: @"Tabs/Tabs-panebar-fill.tiff"];
      cRect.origin.y += 1;
      cRect.origin.x += 0.5;
      cRect.size.width -= 2;
	//cRect.size.height -= [img size].height + [bar size].height;
	cRect.size.height -= ([img size].height - [bar size].height);
//      cRect.size.height -= 18.5;
    }

  if (_type == NSNoTabsBezelBorder)
    {
      cRect.origin.y += 1;
      cRect.origin.x += 0.5;
      cRect.size.width -= 2;
      cRect.size.height -= 2;
    }

  if (_type == NSBottomTabsBezelBorder)
    {
      cRect.size.height -= 8;
      cRect.origin.y = 8;
    }

  return cRect;
}


@end

