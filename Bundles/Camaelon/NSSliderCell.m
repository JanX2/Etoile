#include "GSDrawFunctions.h"

@interface NSSliderCell (theme)
@end

@implementation NSSliderCell (theme)

- (void) drawBarInside: (NSRect)rect flipped: (BOOL)flipped
{
  	//NSImage* knobImage = nil;
	if (_isVertical)
	{
// FIXME: I fail to understand why the knob size used in this way could play a 
// role in the drawing of the track. Probably remove it. However knob size 
// related code is probably needed to center the vertical track horizontally in 
// the slider frame (supposing this frame is equal to rect here).
#if 0
			knobImage = [NSImage imageNamed: @"Slider/Slider-vertical-thumb.tiff"];
			
			float hKnob = [knobImage size].height;
         	rect.origin.y += hKnob / 2;
          	rect.size.height -= hKnob;
#endif

			CLCompositor* compositor = [CLVBoxCompositor new];
			[compositor addImage: [NSImage imageNamed: @"Slider/Slider-vertical-track-caps.tiff"]
				named: @"caps"];
			[compositor addImage: [NSImage imageNamed: @"Slider/Slider-vertical-track-fill.tiff"]
				named: @"fill"];
			[compositor drawInRect: rect flipped: flipped];
			[compositor release];
	}
	else
	{
// FIXME: I fail to understand why the knob size used in this way could play a 
// role in the drawing of the track. Probably remove it. However knob size 
// related code is probably needed to center the horizontal track vertically in 
// the slider frame (supposing this frame is equal to rect here).
#if 0
			knobImage = [NSImage imageNamed: @"Slider/Slider-horizontal-thumb.tiff"];

			float wKnob = [knobImage size].width;
         	rect.origin.x += wKnob / 2;
          	rect.size.width -= wKnob;
#endif
			CLCompositor* compositor = [CLHBoxCompositor new];
			[compositor addImage: [NSImage imageNamed: @"Slider/Slider-horizontal-track-caps.tiff"]
				named: @"caps"];
			[compositor addImage: [NSImage imageNamed: @"Slider/Slider-horizontal-track-fill.tiff"]
				named: @"fill"];
			[compositor drawInRect: rect flipped: flipped];
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

- (void) drawKnob: (NSRect)knobRect
{
  NSImage* knobImage = nil;
  NSPoint point = NSMakePoint (knobRect.origin.x, knobRect.origin.y);
  
  if (_isVertical)
  {
	knobImage = [NSImage imageNamed: @"Slider/Slider-vertical-thumb.tiff"];
	point.y += [knobImage size].height;
  }
  else
  {
	knobImage = [NSImage imageNamed: @"Slider/Slider-horizontal-thumb.tiff"];
	point.y += [knobImage size].height;
  }

  [knobImage compositeToPoint: point operation: NSCompositeSourceOver];
}

// NOTE: The following method isn't overriden but we may want to because it 
// would avoid running GNUstep specific code like loading GNUstep slider images.
// In a long term perspective, this method probably needs to be further 
// modularized on GNUstep side.
// - (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView

- (void) _drawBorderAndBackgroundWithFrame: (NSRect)cellFrame 
                                    inView: (NSView*)controlView
{
	if ([controlView isOpaque])
	{
		[THEME drawWindowBackground: cellFrame on: controlView];
	}
	else /* Default case that renders transparent areas as expected */
	{
		[[NSColor clearColor] set];
		NSRectFill (cellFrame);	
	}
}

/* NSCell overidden methods to ignore border and bezel */

- (NSSize) cellSize
{
	NSAssert1(_cell_image != nil, @"Slider cell %@ must never have a nil "
		@"_cell_image", self);
  
 	return [_cell_image size];
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
 	return theRect;
}

@end

