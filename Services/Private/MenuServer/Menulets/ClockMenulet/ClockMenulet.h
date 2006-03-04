
#import <Foundation/NSObject.h>
#import "../../EtoileMenulet.h"

@class NSTextField, NSTimer;

@interface ClockMenulet : NSObject <EtoileMenulet>
{
  NSTimer * timer;
  NSTextField * view;

  int hour, minute, day;
}

- (NSView *) menuletView;

- (void) updateClock;

@end
