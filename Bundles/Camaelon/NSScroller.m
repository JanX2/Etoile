#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"
#include "GSDrawFunctions.h"

static  NSButtonCell* upCell;
static  NSButtonCell* downCell;
static  NSButtonCell* leftCell;
static  NSButtonCell* rightCell;
static  NSButtonCell* knobCell;

@interface NSScroller (theme)
- (BOOL) isHorizontal;
- (void) drawKnobSlotOn: (NSRect) rect knobPresent: (BOOL) knob;
@end

@implementation NSScroller (theme)

- (void) _setTargetAndActionToCells
{
  [upCell setTarget: _target];
  [upCell setAction: _action];

  [downCell setTarget: _target];
  [downCell setAction: _action];

  [leftCell setTarget: _target];
  [leftCell setAction: _action];

  [rightCell setTarget: _target];
  [rightCell setAction: _action];

  [knobCell setTarget: _target];
  [knobCell setAction: _action];
}

- (void) drawParts
{
  /*
   * Create the class variable button cells if they do not yet exist.
   */
  if (knobCell)
    return;

  upCell = [NSButtonCell new];
  [upCell setHighlightsBy: NSChangeBackgroundCellMask | NSContentsCellMask];
  //[upCell setImage: [NSImage imageNamed: @"common_ArrowUp"]];
  //[upCell setAlternateImage: [NSImage imageNamed: @"common_ArrowUpH"]];
  [upCell setImagePosition: NSImageOnly];
  [upCell setContinuous: YES];
  [upCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [upCell setPeriodicDelay: 0.3 interval: 0.03];

  downCell = [NSButtonCell new];
  [downCell setHighlightsBy: NSChangeBackgroundCellMask | NSContentsCellMask];
  //[downCell setImage: [NSImage imageNamed: @"common_ArrowDown"]];
  //[downCell setAlternateImage: [NSImage imageNamed: @"common_ArrowDownH"]];
  [downCell setImagePosition: NSImageOnly];
  [downCell setContinuous: YES];
  [downCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [downCell setPeriodicDelay: 0.3 interval: 0.03];

  leftCell = [NSButtonCell new];
  [leftCell setHighlightsBy: NSChangeBackgroundCellMask | NSContentsCellMask];
//  [leftCell setImage: [NSImage imageNamed: @"common_ArrowLeft"]];
//  [leftCell setAlternateImage: [NSImage imageNamed: @"common_ArrowLeftH"]];
  [leftCell setImagePosition: NSImageOnly];
  [leftCell setContinuous: YES];
  [leftCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [leftCell setPeriodicDelay: 0.3 interval: 0.03];

  rightCell = [NSButtonCell new];
  [rightCell setHighlightsBy: NSChangeBackgroundCellMask | NSContentsCellMask];
//  [rightCell setImage: [NSImage imageNamed: @"common_ArrowRight"]];
//  [rightCell setAlternateImage: [NSImage imageNamed: @"common_ArrowRightH"]];
  [rightCell setImagePosition: NSImageOnly];
  [rightCell setContinuous: YES];
  [rightCell sendActionOn: (NSLeftMouseDownMask | NSPeriodicMask)];
  [rightCell setPeriodicDelay: 0.3 interval: 0.03];

  knobCell = [NSButtonCell new];
  [knobCell setButtonType: NSMomentaryChangeButton];
  [knobCell setImage: [NSImage imageNamed: @"common_Dimple"]];
  [knobCell setImagePosition: NSImageOnly];
}


- (BOOL) isHorizontal
{
	return _isHorizontal;
}

+ (float) scrollerWidth
{
	NSImage* img = [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-fill.tiff"];
	return [img size].width;
}

- (void) drawKnobSlotOn: (NSRect) rect knobPresent: (BOOL) knob buttonPressed: (int) button
{
	if (_isHorizontal)
	{
		[GSDrawFunctions drawHorizontalScrollerSlot: rect knobPresent: knob 
			buttonPressed: button on: self];
	}
	else
	{
		[GSDrawFunctions drawVerticalScrollerSlot: rect knobPresent: knob 
			buttonPressed: button on: self];
	}
}

- (void) drawKnob
{
	NSRect knob = [self rectForPart: NSScrollerKnob];
	if (_isHorizontal)
	{
		knob.origin.y -= 2;
	}
	else
	{
		knob.origin.x -= 2;
	}
//[[_window backgroundColor] set];
//	NSRectFill (knob);
	//if (_isHorizontal)
/*
	{
		knob.origin.y += 1;
		knob.size.height -= 2;
	}
	//else
	{
		knob.origin.x += 1;
		knob.size.width -= 2;
	}
*/
/*	
	NSButtonCell* kCell = [NSButtonCell new];
	[kCell setButtonType: NSMomentaryChangeButton];
	[kCell setImage: [NSImage imageNamed: @"common_Dimple"]];
	[kCell setImagePosition: NSImageOnly];
  	[kCell drawWithFrame: knob inView: self];
*/
	if (_isHorizontal)
	{
		[GSDrawFunctions drawHorizontalScrollerKnob: knob on: self];
	}
	else
	{
		[GSDrawFunctions drawVerticalScrollerKnob: knob on: self];
	}
}

- (void) trackScrollButtons: (NSEvent*) theEvent
{
  id		theCell = nil;
  NSRect	rect;

  [self lockFocus];

  _hitPart = [self testPart: [theEvent locationInWindow]];
  rect = [self rectForPart: _hitPart];
  int button = 0;

  switch (_hitPart)
  {
  	case NSScrollerIncrementLine:
		if ([theEvent modifierFlags] & NSAlternateKeyMask)
		{
			_hitPart = NSScrollerIncrementPage;
		}
	case NSScrollerIncrementPage:
		theCell = (_isHorizontal ? rightCell : downCell);
		button = (_isHorizontal ? 2 : 1);
		break;
	case NSScrollerDecrementLine:
		if ([theEvent modifierFlags] & NSAlternateKeyMask)
		{
			_hitPart = NSScrollerDecrementPage;
		}
	case NSScrollerDecrementPage:
		theCell = (_isHorizontal ? leftCell : upCell);
		button = (_isHorizontal ? 1 : 2);
		break;
	default:
		theCell = nil;
		break;
  }

  NSLog (@"the cell : %@", theCell);

  if (theCell)
  {
	  [theCell highlight: YES withFrame: rect inView: self];
  	  [self drawKnobSlotOn: [self bounds] knobPresent: YES buttonPressed: button];
	  [self drawKnob];
	  [_window flushWindow];

	  [theCell trackMouse: theEvent
		  inRect: rect
		  ofView: self
		  untilMouseUp: YES];

	  [theCell highlight: NO withFrame: rect inView: self];
  	  [self drawKnobSlotOn: [self bounds] knobPresent: YES buttonPressed: 0];
	  [self drawKnob];
	  [_window flushWindow];
  }
  [self unlockFocus];
}

- (void) drawRect: (NSRect)rect
{
	//[[NSColor redColor] set];
	//NSRectFill (rect);
  static NSRect rectForPartIncrementLine;
  static NSRect rectForPartDecrementLine;
  static NSRect rectForPartKnobSlot;
  
  if (_cacheValid == NO)
    {
      rectForPartIncrementLine = [self rectForPart: NSScrollerIncrementLine];
      rectForPartDecrementLine = [self rectForPart: NSScrollerDecrementLine];
      rectForPartKnobSlot = [self rectForPart: NSScrollerKnobSlot];
	rectForPartKnobSlot = rect;
    }

//  [[_window backgroundColor] set];
//  NSRectFill (rect);

 // if (NSIntersectsRect (rect, rectForPartKnobSlot) == YES)
    {
    BOOL knob = NO;
    NSRect kr = [self rectForPart: NSScrollerKnob];
    if (kr.size.height > 0) knob = YES;

      int buttonPressed = 0;
      [self drawKnobSlotOn: [self bounds] knobPresent: knob buttonPressed: buttonPressed];
     if (knob) [self drawKnob];
    }

/*
  if (NSIntersectsRect (rect, rectForPartDecrementLine) == YES)
    {
      [self drawArrow: NSScrollerDecrementArrow highlight: NO];
    }
  if (NSIntersectsRect (rect, rectForPartIncrementLine) == YES)
    {
      [self drawArrow: NSScrollerIncrementArrow highlight: NO];
    }
*/
}

@end
