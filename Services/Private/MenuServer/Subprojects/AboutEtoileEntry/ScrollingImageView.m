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
#import <AppKit/NSTextView.h>

@interface ScrollingImageView (Private)

- (void) buildTextView;

@end

@implementation ScrollingImageView (Private)

- (void) buildTextView
{
  textView = [[NSTextView alloc]
    initWithFrame: NSMakeRect(0, -250, NSWidth ([self frame]), 250)];

  [textView setDrawsBackground: NO];
  [textView setEditable: NO];
  [textView setSelectable: NO];

  [self addSubview: textView];
}

@end

@implementation ScrollingImageView

- (void) dealloc
{
  TEST_RELEASE (scrolledImage);
  TEST_RELEASE (textView);
  
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

  // widen the text view and position it below the visible area
  frame = [textView frame];
  frame.origin.x = 0;
  frame.size.width = NSWidth ([self frame]);
  frame.origin.y = -NSHeight (frame);

  [textView setFrame: frame];

  NSLog (@"new text view frame is %@", NSStringFromRect (frame));
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
/*  NSImage * backImage = [self image];

  if (backImage != nil)
    {
      [backImage compositeToPoint: r.origin
                         fromRect: r
                        operation: NSCompositeCopy];
    }*/
  [super drawRect: r];

  if (scrolledImage != nil)
    {
      NSRect frame = [self frame];
      NSSize imgSize = [scrolledImage size];
      NSPoint compositingPoint;

      // if we've scrolled off the image and text view, we'll need to composite
      // the image at the bottom
/*      if (currentOffset + NSHeight (frame) >= imgSize.height +
        NSHeight ([textView frame]))
        {
        }
      else*/
        {
          compositingPoint =
            NSMakePoint ((NSWidth (frame) - imgSize.width) / 2,
                         ((NSHeight (frame) - imgSize.height) / 2) +
                         currentOffset);

          if (!NSIsEmptyRect (NSIntersectionRect (NSMakeRect (compositingPoint.x,
                                                  compositingPoint.y,
                                                  imgSize.width,
                                                  imgSize.height),
                              r)))
            {
//              [scrolledImage compositeToPoint: compositingPoint
//                                    operation: NSCompositeSourceOver];
            }
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

          inv = NS_MESSAGE (self, progressAnimation);
          [inv setTarget: self];
          [inv setSelector: @selector (progressAnimation)];

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
  enum {
    AnimationStep = 2
  };

  currentOffset += AnimationStep;

  // stop if we've scrolled enough, or our window isn't visible anymore
  if (NSMinY ([textView frame]) > NSHeight (frame) ||
    [[self window] isVisible] == NO)
    {
      [self stopAnimation: self];
    }
  else
    {
      NSRect r =
        NSMakeRect ((NSWidth (frame) - imgSize.width) / 2,
                    (NSHeight (frame) - imgSize.height) / 2 + currentOffset -
                    AnimationStep,
                    imgSize.width, imgSize.height + AnimationStep);

      if (NSMinY (r) < NSHeight (frame))
        {
//          [self setNeedsDisplayInRect: r];
        }
      
      r = [textView frame];
      r.origin.y = currentOffset - NSHeight (r);
      [textView setFrame: r];
      [textView setNeedsDisplay: YES];
    }
}

@end
