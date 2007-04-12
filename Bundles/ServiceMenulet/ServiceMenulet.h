#import <AppKit/AppKit.h>
#import "EtoileMenulet.h"

@class ServiceButton;

@interface ServiceMenulet : NSObject <EtoileMenulet>
{
  ServiceButton *view;
}

- (NSView *) menuletView;

@end
