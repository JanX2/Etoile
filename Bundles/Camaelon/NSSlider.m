#include "GSDrawFunctions.h"

@interface NSSlider (theme)
@end

@implementation NSSlider (theme)

- (BOOL) isOpaque { return YES; }

/*
- (void) trackKnob: (NSEvent*)theEvent knobRect: (NSRect)knobRect
{ 
  NSApplication *app = [NSApplication sharedApplication];
  unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
                          | NSLeftMouseDraggedMask | NSMouseMovedMask
                          | NSPeriodicMask;
  NSPoint point = [self convertPoint: [theEvent locationInWindow]
                        fromView: nil];
  NSEventType eventType = [theEvent type];
  BOOL isContinuous = [_cell isContinuous];
  float oldFloatValue = [_cell floatValue];
  id target = [_cell target];
  SEL action = [_cell action];
  NSDate *distantFuture = [NSDate distantFuture];
  NSRect slotRect = [_cell trackRect];
  BOOL isVertical = [_cell isVertical];
  float minValue = [_cell minValue];
  float maxValue = [_cell maxValue];

  [NSEvent startPeriodicEventsAfterDelay: 0.05 withPeriod: 0.05];
  [[NSRunLoop currentRunLoop] limitDateForMode: NSEventTrackingRunLoopMode];

  [self lockFocus];

  while (eventType != NSLeftMouseUp)
    {
      theEvent = [app nextEventMatchingMask: eventMask
                                  untilDate: distantFuture
                                     inMode: NSEventTrackingRunLoopMode
                                    dequeue: YES];
      eventType = [theEvent type];

      if (eventType != NSPeriodic)
        {
          point = [self convertPoint: [theEvent locationInWindow]
                        fromView: nil];
        }
      else
        {
          if (point.x != knobRect.origin.x || point.y != knobRect.origin.y)
            {
              float floatValue;
              floatValue = _floatValueForMousePoint (point, knobRect,
                                                     slotRect, isVertical, 
                                                     minValue, maxValue, 
                                                     _cell, 
                                                     _rFlags.flipped_view); 
              if (floatValue != oldFloatValue)
                {
                  [_cell setFloatValue: floatValue];
                  [_cell drawWithFrame: _bounds inView: self];
                  [_window flushWindow];
                  if (isContinuous)
                    {
                      [self sendAction: action to: target];
                    }
                  oldFloatValue = floatValue;
                }
              knobRect.origin = point;
            }
        }
    }
  [self unlockFocus];
  // If the control is not continuous send the action at the end of the drag
  if (!isContinuous)
    {
      [self sendAction: action to: target];
    }
  [NSEvent stopPeriodicEvents];
}
*/

@end
