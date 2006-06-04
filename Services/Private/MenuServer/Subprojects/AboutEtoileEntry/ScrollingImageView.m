/*
 * Created by diablos on 2006-05-08 22:19:27 +0200
 * All Rights Reserved
 */

#import "ScrollingImageView.h"

#import <Foundation/NSException.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTimer.h>

#import <AppKit/NSImage.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextView.h>

#import <AppKit/PSOperators.h>

// a special subclass to make mouse-down events drop through
// the receiver and hit it's superview
@interface _ScrollingImageViewTextView : NSTextView

@end

@implementation _ScrollingImageViewTextView

- (void) mouseDown: (NSEvent *) ev
{
  [[self superview] mouseDown: ev];
}

@end

@interface ScrollingImageView (Private)

- (void) buildTextView;

@end

@implementation ScrollingImageView (Private)

- (void) buildTextView
{
  NSRect myFrame = [self frame];

  textView = [[_ScrollingImageViewTextView alloc]
    initWithFrame: NSMakeRect(0, -10e6, NSWidth (myFrame), 10e6)];

  [textView setDrawsBackground: NO];
  [textView setEditable: NO];
  [textView setSelectable: NO];
  [textView setVerticallyResizable: YES];
  [textView setHorizontallyResizable: YES];
  [textView setMaxSize: NSMakeSize (NSWidth (myFrame), 10e5)];
  [textView setMinSize: NSMakeSize (0, 0)];
  [[textView textContainer] setWidthTracksTextView: YES];

  [self addSubview: textView];
}

@end

@implementation ScrollingImageView

- (void) dealloc
{
  TEST_RELEASE (scrolledImage);
  TEST_RELEASE (textView);

  if (animationTimer != nil)
    {
      [animationTimer invalidate];
      animationTimer = nil;
    }
  
  [super dealloc];
}

- (void) setScrolledImage: (NSImage *) anImage
{
  NSAssert (isAnimationRunning == NO, @"Tried to set scrolled image while "
    @"we were animating it.");

  ASSIGN (scrolledImage, anImage);
  [self setNeedsDisplay: YES];
}

- (NSImage *) scrolledImage
{
  return scrolledImage;
}

- (void) setScrolledRTF: (NSData *) rtfData
{
  NSRange r;
  NSRect frame;

  NSAssert (isAnimationRunning == NO, @"Tried to set scrolled RTF data "
    @"while we were animating it.");

  if (textView == nil)
    {
      [self buildTextView];
    }

  r = NSMakeRange (0, [[textView textStorage] length]);
  [textView replaceCharactersInRange: r withRTF: rtfData];
  [textView sizeToFit];

  // position the text view below the visible area
  frame = [textView frame];

  frame.origin.x = (NSWidth ([self frame]) - NSWidth (frame)) / 2;
  frame.origin.y = -NSHeight (frame);

  [textView setFrame: frame];
}

- (void) awakeFromNib
{
  if (textView == nil)
    {
      [self buildTextView];
    }
}

- (void) drawRect: (NSRect) r
{
  NSImage * backImage = [self image];

  if (backImage != nil)
    {
      [backImage compositeToPoint: r.origin
                         fromRect: NSMakeRect (r.origin.x,
                                               r.origin.y,
                                               r.size.width + 1,
                                               r.size.height + 1)
                        operation: NSCompositeCopy];
    }

  if (scrolledImage != nil)
    {
      NSRect frame = [self frame];
      NSSize imgSize = [scrolledImage size];
      NSPoint compositingPoint;
      NSRect drawingRect;

      compositingPoint =
        NSMakePoint ((NSWidth (frame) - imgSize.width) / 2,
                     ((NSHeight (frame) - imgSize.height) / 2) +
                     currentOffset);

      drawingRect = NSMakeRect (compositingPoint.x,
                                compositingPoint.y,
                                imgSize.width,
                                imgSize.height);
      drawingRect = NSIntersectionRect (drawingRect, r);

      // draw only if necessary
      if (!NSIsEmptyRect (drawingRect))
        {
          drawingRect.origin = NSZeroPoint;

          [scrolledImage compositeToPoint: compositingPoint
                                 fromRect: drawingRect
                                operation: NSCompositeSourceOver];
        }
    }
}

- (void) mouseDown: (NSEvent *) ev
{
  [self setAnimationRunning: !isAnimationRunning];
}

- (void) startAnimation: sender
{
  [self setAnimationRunning: YES];
}

- (void) stopAnimation: sender
{
  [self setAnimationRunning: NO];
}

- (void) setAnimationRunning: (BOOL) flag
{
  if (flag != isAnimationRunning)
    {
      isAnimationRunning = flag;

      if (isAnimationRunning)
        {
          // start the animation
          NSInvocation * inv;

          // if there's no image to animate, don't do anything
          if (scrolledImage == nil)
            {
              return;
            }

          inv = [NSInvocation invocationWithMethodSignature: [self
            methodSignatureForSelector: @selector (progressAnimation)]];
          [inv setSelector: @selector (progressAnimation)];
          [inv setTarget: self];

           // animate at 20 fps
          animationTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05
                                                        invocation: inv
                                                           repeats: YES];
        }
      else
        {
          NSRect r;
        
          // stop the animation
          [animationTimer invalidate];
          animationTimer = nil;
          scrollBackPhase = NO;

          currentOffset = 0;
          [self setNeedsDisplay: YES];
          
          r = [textView frame];
          r.origin.y = -NSHeight (r);
          [textView setFrame: r];
        }
    }
}

- (BOOL) isAnimationRunning
{
  return isAnimationRunning;
}

- (void) progressAnimation
{
  NSRect frame = [self frame];
  NSSize imgSize = [scrolledImage size];
  NSRect r;
  enum {
    AnimationStep = 2
  };

  if (NSMinY ([textView frame]) > NSHeight (frame) || scrollBackPhase == YES)
    {
      if (scrollBackPhase == NO)
        {
          scrollBackPhase = YES;
          currentOffset = NSHeight (frame) -
            ((NSHeight (frame) - imgSize.height) / 2);
          
          r = [textView frame];
          r.origin.y = -NSHeight (r);
          [textView setFrame: r];
          [textView setNeedsDisplay: YES];
        }

      currentOffset -= AnimationStep;

      r = NSMakeRect ((NSWidth (frame) - imgSize.width) / 2,
                      (NSHeight (frame) - imgSize.height) / 2 + currentOffset,
                      imgSize.width,
                      imgSize.height + AnimationStep);
      [self setNeedsDisplayInRect: r];
      
      if (currentOffset < 0)
        {
          [self stopAnimation: self];
        }
    }
  else
    {
      NSRect baseRect;

      r = NSMakeRect ((NSWidth (frame) - imgSize.width) / 2,
                      (NSHeight (frame) - imgSize.height) / 2 + currentOffset,
                      imgSize.width,
                      imgSize.height + AnimationStep);
      r = NSIntersectionRect (r,
        NSMakeRect (0, 0, NSWidth (frame), NSHeight (frame)));

      if (!NSIsEmptyRect (r))
        {
          [self setNeedsDisplayInRect: r];
        }
    
      currentOffset += AnimationStep;

      r = [textView frame];
      r.origin.y = currentOffset - NSHeight (r);
      [textView setFrame: r];

      baseRect = NSMakeRect (0, 0, NSWidth (frame), NSHeight (frame));
      r = NSIntersectionRect (r, baseRect);
       // grow the rectange downwards, because we want to redraw not
       // only where the text view is now, but also where it has been
       // before, otherwise we'll see leftover drawing there
      if (NSMinY (r) > 0)
        {
          r.origin.y -= AnimationStep;
          r.size.height += AnimationStep;
        }
      [self setNeedsDisplayInRect: r];
    }
}

@end
