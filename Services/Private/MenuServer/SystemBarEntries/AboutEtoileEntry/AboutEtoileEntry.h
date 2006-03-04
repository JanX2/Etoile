
#import <Foundation/NSObject.h>
#import "../../EtoileSystemBarEntry.h"

@class NSWindow;

@interface AboutEtoileEntry : NSObject <EtoileSystemBarEntry>
{
  NSWindow * window;
}

- (void) activate;

@end
