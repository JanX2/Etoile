#include "GSDrawFunctions.h"

@interface NSSliderCell (theme)
@end

@implementation NSSliderCell (theme)

- (void) drawBarInside: (NSRect)rect flipped: (BOOL)flipped
{
  [[NSColor controlShadowColor] set];           

	if (_isVertical)
	{
		  [GraphicToolbox drawVerticalButton: NSMakeRect (rect.origin.x,rect.origin.y,
				rect.size.width,rect.size.height) 
			withCaps: [NSImage imageNamed: @"Slider/Slider-vertical-track-caps.tiff"]
			filledWith: [NSImage imageNamed: @"Slider/Slider-vertical-track-fill.tiff"]];
	}
	else
	{
		  [GraphicToolbox drawHorizontalButton: NSMakeRect (rect.origin.x,rect.origin.y,
				rect.size.width,rect.size.height) 
			withLeftCap: [NSImage imageNamed: @"Slider/Slider-horizontal-track-caps.tiff"]
			rightCap: [NSImage imageNamed: @"Slider/Slider-horizontal-track-caps.tiff"]
			filledWith: [NSImage imageNamed: @"Slider/Slider-horizontal-track-fill.tiff"] flipped: NO];
	}

  //NSRectFill(rect);
/*

  float wBar  = 5;

  float hKnob = [_knobCell cellSize].height;
  float wKnob = [_knobCell cellSize].width;

  if (_isVertical)
  {
          rect.origin.x += (rect.size.width - wBar)/2;
          rect.size.width = wBar;
          rect.origin.y += hKnob / 2;
          rect.size.height -= hKnob;
  }
  else
  {
          rect.origin.y += (rect.size.height - wBar)/2;
          rect.size.height = wBar;
          rect.origin.x += wKnob / 2;
          rect.size.width -= wKnob;
  }
  
  [[NSColor scrollBarColor] set];
  NSRectFill(rect);
*/
}

- (NSRect) knobRectFlipped: (BOOL)flipped
{
  NSImage       *image = [_knobCell image];
  NSSize        size;
  NSPoint       origin;
  float         floatValue = [self floatValue];

  if (_isVertical && flipped)
    {
      floatValue = _maxValue + _minValue - floatValue;
    }

  floatValue = (floatValue - _minValue) / (_maxValue - _minValue);

  size = [image size];

  if (_isVertical == YES)
    {
      size.width -= 2;
      origin = _trackRect.origin;
      origin.y += (_trackRect.size.height - size.height) * floatValue;
    }
  else
    {
      size.height -= 2;
      origin = _trackRect.origin;
      origin.x += (_trackRect.size.width - size.width) * floatValue;
    }

  return NSMakeRect (origin.x, origin.y, size.width, size.height);
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  _cell.is_bordered = NO;
  _cell.is_bezeled = YES;
  //[GSDrawFunctions drawGrayBezelRound: cellFrame :NSZeroRect];
  //[[NSColor greenColor] set];
  //NSRectFill (cellFrame);
//  [GSDrawFunctions drawWindowBackground: cellFrame on: controlView];
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}
- (void) drawKnob: (NSRect)knobRect
{
  NSImage* knobImage = nil;
  if (_isVertical)
  {
	knobImage = [NSImage imageNamed: @"Slider/Slider-vertical-thumb.tiff"];
	[knobImage compositeToPoint: NSMakePoint (knobRect.origin.x-3,knobRect.origin.y)
			operation: NSCompositeSourceOver];
  }
  else
  {
	knobImage = [NSImage imageNamed: @"Slider/Slider-horizontal-thumb.tiff"];
	[knobImage compositeToPoint: NSMakePoint (knobRect.origin.x,knobRect.origin.y)
			operation: NSCompositeSourceOver];
  }
/*
	//[[NSColor controlBackgroundColor] set];
	//NSRectFill (knobRect);
	//[GSDrawFunctions drawButton: knobRect :NSZeroRect];
	[GSDrawFunctions drawButton: knobRect inView: self highlighted: NO];
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSBezierPath* path2 = [NSBezierPath bezierPath];
	[path setLineWidth: 1.5];
	[path2 setLineWidth: 1.5];
	if (knobRect.size.width > knobRect.size.height)
	{
		// Horizontal
		[path moveToPoint: NSMakePoint (knobRect.origin.x+
			knobRect.size.width/2+1, knobRect.origin.y)];
		[path lineToPoint: NSMakePoint (knobRect.origin.x+
			knobRect.size.width/2+1,
			knobRect.origin.y+knobRect.size.height)];
		[path2 moveToPoint: NSMakePoint (knobRect.origin.x+
			knobRect.size.width/2-1, knobRect.origin.y)];
		[path2 lineToPoint: NSMakePoint (knobRect.origin.x+
			knobRect.size.width/2-1,
			knobRect.origin.y+knobRect.size.height)];
	}
	else
	{
		// Vertical
		[path moveToPoint: NSMakePoint (knobRect.origin.x,
			knobRect.size.height/2 -1+ knobRect.origin.y)];
		[path lineToPoint: NSMakePoint (knobRect.origin.x+
			knobRect.size.width,
			knobRect.origin.y-1+knobRect.size.height/2)];
		[path2 moveToPoint: NSMakePoint (knobRect.origin.x,
			knobRect.size.height/2 +1 +knobRect.origin.y)];
		[path2 lineToPoint: NSMakePoint (knobRect.origin.x+
			knobRect.size.width,
			knobRect.origin.y+knobRect.size.height/2 +1)];
	}
	[[NSColor controlLightHighlightColor] set];
	[[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 0.9] set];
	[path stroke];
	[[NSColor controlShadowColor] set];
	[[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.5] set];
	[path2 stroke];
*/

}
@end
