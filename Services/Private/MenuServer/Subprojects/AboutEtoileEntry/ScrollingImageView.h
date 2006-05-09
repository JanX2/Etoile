/*
 * Created by diablos on 2006-05-08 22:19:27 +0200
 * All Rights Reserved
 */

#ifndef _SCROLLINGIMAGEVIEW_H_
#define _SCROLLINGIMAGEVIEW_H_

#import <AppKit/NSImageView.h>

@class NSImage,
       NSTimer,
       NSTextView;

@interface ScrollingImageView : NSImageView
{
  NSImage * scrolledImage;
  NSTextView * textView;

  // weak reference - the runloop retains the timer
  NSTimer * animationTimer;

  double currentOffset;
  BOOL isAnimationRunning;
}

- (void) setScrolledImage: (NSImage *) anImage;
- (NSImage *) scrolledImage;

- (void) setScrolledRTF: (NSData *) rtfData;

- (void) startAnimation: sender;
- (void) stopAnimation: sender;

- (void) setAnimationRunning: (BOOL) flag;
- (BOOL) isAnimationRunning;

- (void) progressAnimation;

@end

#endif // _SCROLLINGIMAGEVIEW_H_
