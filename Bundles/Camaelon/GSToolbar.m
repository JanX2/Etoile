
#import "GSToolbar.h"

#import "GSDrawFunctions.h"
#import "NSColor.h"

@interface NSWindow (private)
-(NSColor*) toolbarColor;
@end

@implementation GSToolbarView (Themeability)

- (BOOL) isOpaque
{
	return NO;
}


- (void) drawRect: (NSRect)aRect
{
  [_clipView setDrawsBackground: NO];
  
  [super drawRect: aRect];
  
  //NSBezierPath *rect = [NSBezierPath bezierPathWithRect: aRect];
  NSRect viewFrame = [self frame];

  //NSImage* filling = [[self window] toolbarFillImage];
  //NSLog(@"fillIMG = %@", filling);
  
  //[filling compositeToPoint: aRect.origin operation: NSCompositeSourceOver];
  
  //[GraphicToolbox fillHorizontalRect: viewFrame withImage: filling];
  [THEME drawVerticalGradient: [[self window] toolbarColor]
       to: [[self window] backgroundColor]
       frame: aRect];
  
  /*
  [[[self window] backgroundColor] set];
  NSRectFill(aRect);
  */

  /*
  if (![BackgroundColor isEqual: [NSColor clearColor]])
    {
      [BackgroundColor set];
      [rect fill];
      [THEME drawVerticalGradient: [[self window] backgroundColor]
	  		to: [NSColor blackColor]
      		frame: rect];
    }
  */
  
  // We draw the border
  [[NSColor windowBorderColor] set];
  
  if (_borderMask & GSToolbarViewBottomBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(0, 0.5) 
                              toPoint: NSMakePoint(viewFrame.size.width, 0.5)];
  }
  if (_borderMask & GSToolbarViewTopBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(0, 
                                         viewFrame.size.height - 0.5) 
                              toPoint: NSMakePoint(viewFrame.size.width, 
                                         viewFrame.size.height -  0.5)];
  }
  if (_borderMask & GSToolbarViewLeftBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(0.5, 0) 
                              toPoint: NSMakePoint(0.5, viewFrame.size.height)];
  }
  if (_borderMask & GSToolbarViewRightBorder)
  {
    [NSBezierPath strokeLineFromPoint: NSMakePoint(viewFrame.size.width - 0.5,0)
                              toPoint: NSMakePoint(viewFrame.size.width - 0.5, 
                                         viewFrame.size.height)];
  }
  
}

@end
