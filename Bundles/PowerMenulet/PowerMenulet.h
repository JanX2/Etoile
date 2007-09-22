#import <AppKit/AppKit.h>
#import "EtoileMenulet.h"
#import <SystemConfig/SCPower.h>

enum PowerLevel
{
	NoPower,
	WiredPower,
	BatteryPower
};

@interface PowerMenulet : NSObject <EtoileMenulet>
{
	SCPower *power;
	NSButton *view;
	NSTimer *timer;
	int batteryLevel;
	NSImage *p0, *p1, *p2, *p3, *p4, *p5, *p6;

	/* Cache */
	NSFileManager *fm;
}

- (NSView *) menuletView;

@end
