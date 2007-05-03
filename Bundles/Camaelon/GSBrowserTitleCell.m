#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"

@interface GSBrowserTitleCell : NSTextFieldCell //NSTableHeaderCell 
{}
@end

@implementation GSBrowserTitleCell (theme)
  
/*
- (void) drawRect: (NSRect) cellFrame
{ 
  NSColor* startColor = [NSColor colorWithCalibratedRed: 0.16 green: 0.26 blue: 0.4 alpha: 1.0];
  NSColor* endColor = [NSColor colorWithCalibratedRed: 0.7 green: 0.75 blue: 0.83 alpha: 1.0];

  [GraphicToolbox drawVerticalGradientOnRect: cellFrame
    withStartColor: startColor
    andEndColor: endColor];
  [GraphicToolbox drawButtonOnRect: cellFrame 
    pushed: GSWViewIsFlipped(ctxt)];
}
*/

- (void) drawWithFrame: (NSRect)cellFrame  inView: (NSView*)controlView
{
  if (NSIsEmptyRect (cellFrame) || ![controlView window])
    {
      return;
    }
   //[GSDrawFunctions drawBrowserHeaderInRect: cellFrame];

//  NSDrawGrayBezel (cellFrame, NSZeroRect);
  _textfieldcell_draws_background = NO;
  [super drawInteriorWithFrame: cellFrame  inView: controlView];
//  NSBezierPath* path = [NSBezierPath bezierPath];
 // [path appendBezierPathWithRect: cellFrame];
//  [path setLineWidth: 1.5];
//  [path stroke];
}
- (NSColor *)textColor
{
	return [THEME browserHeaderTextColor];
} 

@end

