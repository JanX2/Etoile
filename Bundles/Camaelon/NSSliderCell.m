#include "GSDrawFunctions.h"

@interface NSSliderCell (theme)
@end

@implementation NSSliderCell (theme)

- (void) drawBarInside: (NSRect)rect flipped: (BOOL)flipped
{
  	NSImage* knobImage = nil;
	if (_isVertical)
	{
			knobImage = [NSImage imageNamed: @"Slider/Slider-vertical-thumb.tiff"];
			
			float hKnob = [knobImage size].height;
         	rect.origin.y += hKnob / 2;
          	rect.size.height -= hKnob;

			CLCompositor* compositor = [CLVBoxCompositor new];
			[compositor addImage: [NSImage imageNamed: @"Slider/Slider-vertical-track-caps.tiff"]
				named: @"caps"];
			[compositor addImage: [NSImage imageNamed: @"Slider/Slider-vertical-track-fill.tiff"]
				named: @"fill"];
			[compositor drawInRect: rect];
			[compositor release];
	}
	else
	{
			knobImage = [NSImage imageNamed: @"Slider/Slider-horizontal-thumb.tiff"];

			float wKnob = [knobImage size].width;
         	rect.origin.x += wKnob / 2;
          	rect.size.width -= wKnob;

			CLCompositor* compositor = [CLHBoxCompositor new];
			[compositor addImage: [NSImage imageNamed: @"Slider/Slider-horizontal-track-caps.tiff"]
				named: @"caps"];
			[compositor addImage: [NSImage imageNamed: @"Slider/Slider-horizontal-track-fill.tiff"]
				named: @"fill"];
			[compositor drawInRect: rect];
			[compositor release];
	}
}

- (NSRect) knobRectFlipped: (BOOL)flipped
{
//  NSImage       *image = [_knobCell image];
  NSSize        size;
  NSPoint       origin;
  float         floatValue = [self floatValue];

  if (_isVertical && flipped)
    {
      floatValue = _maxValue + _minValue - floatValue;
    }

  floatValue = (floatValue - _minValue) / (_maxValue - _minValue);

  //size = [image size];

  // TODO: get rid of theses knobImage calls and do that properly..

  NSImage* knobImage = nil;
  if (_isVertical)
  {
	knobImage = [NSImage imageNamed: @"Slider/Slider-vertical-thumb.tiff"];
  }
  else
  {
	knobImage = [NSImage imageNamed: @"Slider/Slider-horizontal-thumb.tiff"];
  }
  size = [knobImage size];

  if (_isVertical == YES)
    {
      origin = _trackRect.origin;
	  origin.x += (_trackRect.size.width - size.width) / 2.0;
      origin.y += (_trackRect.size.height - size.height) * floatValue;
    }
  else
    {
      origin = _trackRect.origin;
      origin.x += (_trackRect.size.width - size.width) * floatValue;
	  origin.y += (_trackRect.size.height - size.height) / 2.0;
    }

  return NSMakeRect (origin.x, origin.y, size.width, size.height);
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  _cell.is_bordered = NO;
  _cell.is_bezeled = YES;
  //[THEME drawGrayBezelRound: cellFrame :NSZeroRect];
  //[[NSColor greenColor] set];
  //NSRectFill (cellFrame);
  [THEME drawWindowBackground: cellFrame on: controlView];
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}
- (void) drawKnob: (NSRect)knobRect
{
  NSImage* knobImage = nil;
  NSPoint point = NSMakePoint (knobRect.origin.x, knobRect.origin.y);
  
  if (_isVertical)
  {
	knobImage = [NSImage imageNamed: @"Slider/Slider-vertical-thumb.tiff"];
  }
  else
  {
	knobImage = [NSImage imageNamed: @"Slider/Slider-horizontal-thumb.tiff"];
  }

  [knobImage compositeToPoint: point operation: NSCompositeSourceOver];
}
@end
