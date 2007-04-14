#import <AppKit/AppKit.h>
#import "EtoileMenulet.h"

enum PowerLevel
{
  NoPower,
  WiredPower,
  BatteryPower
};

@interface PowerMenulet : NSObject <EtoileMenulet>
{
  NSButton *view;
  NSTimer *timer;
  int batteryLevel;

  /* Cache */
  NSFileManager *fm;
}

- (NSView *) menuletView;

@end
