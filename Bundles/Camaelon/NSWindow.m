#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSWindowDecorationView.h"
#include "GSDrawFunctions.h"
#include "GraphicToolbox.h"

#define TITLE_HEIGHT 20.0
#define RESIZE_HEIGHT 9.0

static NSDictionary *titleTextAttributes[3];
static NSColor *titleColor[3];

@implementation  GSStandardWindowDecorationView (theme)

-(void) updateRects
{
  NSImage* caps= [NSImage imageNamed: @"Window/Window-titlebar-caps.tiff"];
  if (hasTitleBar)
    titleBarRect = NSMakeRect(0.0, _frame.size.height - [caps size].height -1,
                              _frame.size.width, [caps size].height);
  if (hasResizeBar)
  {
    NSImage* resizeCaps = [NSImage imageNamed: @"Window/Window-resizebar-caps.tiff"];
    resizeBarRect = NSMakeRect(0.0, 0.0, _frame.size.width, [resizeCaps size].height);
  }
  else
  {
    NSImage* resizeCaps = [NSImage imageNamed: @"Window/Window-resizebar-caps-unselected.tiff"];
    resizeBarRect = NSMakeRect(0.0, 0.0, _frame.size.width, [resizeCaps size].height);
  }
    //resizeBarRect = NSMakeRect(0.0, 0.0, _frame.size.width, RESIZE_HEIGHT);

  if (hasCloseButton)
    {
      NSImage* imgCloseButton = [NSImage imageNamed: @"Window/Window-titlebar-closebutton.tiff"];
      float imgWidth = [imgCloseButton size].width;
      float imgHeight = [imgCloseButton size].height;
      float border = (titleBarRect.size.height - imgHeight)/2;
      closeButtonRect = NSMakeRect (
        _frame.size.width - imgWidth - border, 
	_frame.size.height - imgHeight - border - 1, 
	imgWidth, imgHeight); 
      [closeButton setFrame: closeButtonRect];
      [closeButton setImage: imgCloseButton];
    }
    [miniaturizeButton setImage: [NSImage imageNamed: @"Window/Window-titlebar-minimizebutton.tiff"]];

  if (hasMiniaturizeButton)
    {
      NSImage* imgMiniaturizeButton = [NSImage imageNamed: 
      	@"Window/Window-titlebar-minimizebutton.tiff"];
      float imgWidth = [imgMiniaturizeButton size].width;
      float imgHeight = [imgMiniaturizeButton size].height;
      float border = ([caps size].height - imgHeight)/2;
      miniaturizeButtonRect = NSMakeRect (border,
        _frame.size.height - imgHeight - border - 1, 
	imgWidth, imgHeight); 
      [miniaturizeButton setFrame: miniaturizeButtonRect];
      [miniaturizeButton setImage: imgMiniaturizeButton];
    }
}

- (void) drawRect: (NSRect)rect
{
//	[[NSColor windowBackgroundColor] set];
//	NSRectFill (rect);
//		NSImage* caps= [NSImage imageNamed: @"Window/Window-titlebar-caps.tiff"];
    contentRect.origin.y -= 1;
    contentRect.size.height += 2;
    [GSDrawFunctions drawWindowBackground: contentRect on: self];
  //  titleBarRect.origin.x -= 1;
  if (hasTitleBar && NSIntersectsRect(rect, titleBarRect))
    {
  titleBarRect.size.height += 1;
	NSRectFillUsingOperation (titleBarRect, NSCompositeClear);
  titleBarRect.size.height -= 1;
//  titleBarRect.size.height = [caps size].height;
      [self drawTitleBar];
    }

  //if (hasResizeBar && NSIntersectsRect(rect, resizeBarRect))
  if (NSIntersectsRect(rect, resizeBarRect))
    {
      NSRectFillUsingOperation (resizeBarRect, NSCompositeClear);
      [self drawResizeBar];
    }
      /*
  if (hasResizeBar || hasTitleBar)
    {
      PSsetlinewidth(1.0);
      [[NSColor blackColor] set];
      if (NSMinX(rect) < 1.0)
        {
          PSmoveto(0.5, 0.0);
          PSlineto(0.5, _frame.size.height - titleBarRect.size.height);
          PSstroke();
        }
      if (NSMaxX(rect) > _frame.size.width - 1.0)
        {
          PSmoveto(_frame.size.width - 0.5, 0.0);
          PSlineto(_frame.size.width - 0.5, _frame.size.height - titleBarRect.size.height);
          PSstroke();
        }
      if (NSMaxY(rect) > _frame.size.height - 1.0)
        {
          PSmoveto(0.0, _frame.size.height - 0.5 - titleBarRect.size.height);
          PSlineto(_frame.size.width, _frame.size.height - 0.5 - titleBarRect.size.height);
          PSstroke();
        }
      if (NSMinY(rect) < 1.0)
        {
          PSmoveto(0.0, 0.5);
          PSlineto(_frame.size.width, 0.5);
          PSstroke();
        }
    }
	*/
/*
	[super drawRect: rect];
*/
}

-(void) drawTitleBar
{
static const NSRectEdge edges[4] = {NSMinXEdge, NSMaxYEdge,
				    NSMaxXEdge, NSMinYEdge};
  float grays[3][4] =
    {{NSLightGray, NSLightGray, NSDarkGray, NSDarkGray},
    {NSWhite, NSWhite, NSDarkGray, NSDarkGray},
    {NSLightGray, NSLightGray, NSBlack, NSBlack}};
  NSRect workRect;
NSString *title = [window title];
NSColorList* colorList = [NSColorList colorListNamed: @"System"];

  /*
  Draw the black border towards the rest of the window. (The outer black
  border is drawn in -drawRect: since it might be drawn even if we don't have
  a title bar.
  */
  //[[NSColor blackColor] set];
//[[NSColor redColor] set];
  [[NSColor windowBackgroundColor] set];

//  PSmoveto(0, NSMinY(titleBarRect) + 0.5);
//  PSrlineto(titleBarRect.size.width, 0);
//  PSstroke();

  /*
  Draw the button-like border.
  */
  workRect = titleBarRect;
  //workRect.origin.x += 1;
  //workRect.origin.y += 1;
  //workRect.size.width -= 2;
  //workRect.size.height -= 2;

  //workRect = NSDrawTiledRects(workRect, workRect, edges, grays[inputState], 4);
 
  /*
  Draw the background.
  */
  [titleColor[inputState] set];
  //NSRectFill(workRect);

  /* Draw the title. */
  if (isTitled)
    {
      NSSize titleSize;
    
/*
      if (hasMiniaturizeButton)
	{
	  workRect.origin.x += 17;
	  workRect.size.width -= 17;
	}
      if (hasCloseButton)
	{
	  workRect.size.width -= 17;
	}

*/

	[closeButton setBordered: NO];
	[miniaturizeButton setBordered: NO];

	if (inputState)
	{
		[GraphicToolbox drawButton: workRect
		withCaps: [NSImage imageNamed: @"Window/Window-titlebar-caps-unselected.tiff"]
		filledWith: [NSImage imageNamed: @"Window/Window-titlebar-fill-unselected.tiff"]];
	}
	else
	{
		[GraphicToolbox drawButton: workRect
		withCaps: [NSImage imageNamed: @"Window/Window-titlebar-caps.tiff"]
		filledWith: [NSImage imageNamed: @"Window/Window-titlebar-fill.tiff"]];
	}
/*
	NSRect outlineRect = workRect;
	//outlineRect.origin.x += 1;
	//outlineRect.size.width -= 2;
	////outlineRect.origin.y -= 1;
	//outlineRect.size.height -= 1;
	NSBezierPath* outlinePath = [NSBezierPath bezierPath];
	[outlinePath appendBezierPathWithTopRoundedCorners: outlineRect withRadius: 8.0];
	[[NSColor blackColor] set];

	NSBezierPath* path = [NSBezierPath bezierPath];
	[path appendBezierPathWithTopRoundedCorners: outlineRect withRadius: 8.0];
	[[NSColor colorWithCalibratedRed: 0.7 green: 0.7 blue: 0.75 alpha: 1.0] set];
	NSColor* start = [NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 1.0];
	NSColor* end   = [NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0];
	
	NSGraphicsContext *ctxt = GSCurrentContext();
	DPSgsave (ctxt);
	[path addClip];
	[GSDrawFunctions drawVerticalGradient: start to: end frame: workRect];
	DPSgrestore (ctxt);
	[outlinePath setLineWidth: 1.5];
  	[[NSColor windowBackgroundColor] set];
	[outlinePath stroke];
	[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 1.0] set];
	[[NSColor blackColor] set];
	[outlinePath stroke];
	//[path fill];
  */
      titleSize = [title sizeWithAttributes: titleTextAttributes[inputState]];
      if (titleSize.width <= workRect.size.width)
	workRect.origin.x += NSMidX(workRect) - titleSize.width / 2;
      workRect.origin.y = NSMidY(workRect) - titleSize.height / 2;
      workRect.size.height = titleSize.height;
      [title drawInRect: workRect
	 withAttributes: titleTextAttributes[inputState]];
    }
}

-(void) drawResizeBar
{
	if (hasResizeBar)
	{
		[GraphicToolbox drawButton: resizeBarRect
			withCaps: [NSImage imageNamed: @"Window/Window-resizebar-caps.tiff"]
			filledWith: [NSImage imageNamed: @"Window/Window-resizebar-fill.tiff"]];
	}
	else if (!hasResizeBar || inputState)
	{
		[GraphicToolbox drawButton: resizeBarRect
			withCaps: [NSImage imageNamed: @"Window/Window-resizebar-caps-unselected.tiff"]
			filledWith: [NSImage imageNamed: @"Window/Window-resizebar-fill-unselected.tiff"]];
	}
		/*
  [[NSColor lightGrayColor] set];
  [[NSColor windowBackgroundColor] set];
  PSrectfill(1.0, 1.0, resizeBarRect.size.width - 2.0, RESIZE_HEIGHT - 3.0);

  PSsetlinewidth(1.0);

//  [[NSColor blackColor] set];
  [[NSColor darkGrayColor] set];
  PSmoveto(0.0, 0.5);
  PSlineto(resizeBarRect.size.width, 0.5);
  PSstroke();

  [[NSColor darkGrayColor] set];
  PSmoveto(1.0, RESIZE_HEIGHT - 0.5);
  PSlineto(resizeBarRect.size.width - 1.0, RESIZE_HEIGHT - 0.5);
  PSstroke();

//  [[NSColor whiteColor] set];
  PSmoveto(1.0, RESIZE_HEIGHT - 1.5);
  PSlineto(resizeBarRect.size.width - 1.0, RESIZE_HEIGHT - 1.5);
  PSstroke();

  // Only draw the notches if there's enough space. 
  if (resizeBarRect.size.width < 30 * 2)
    return;

  [[NSColor darkGrayColor] set];
  PSmoveto(27.5, 1.0);
  PSlineto(27.5, RESIZE_HEIGHT - 2.0);
  PSmoveto(resizeBarRect.size.width - 28.5, 1.0);
  PSlineto(resizeBarRect.size.width - 28.5, RESIZE_HEIGHT - 2.0);
  PSstroke();

//  [[NSColor whiteColor] set];
  PSmoveto(28.5, 1.0);
  PSlineto(28.5, RESIZE_HEIGHT - 2.0);
  PSmoveto(resizeBarRect.size.width - 27.5, 1.0);
  PSlineto(resizeBarRect.size.width - 27.5, RESIZE_HEIGHT - 2.0);
  PSstroke();
  */
}
@end
