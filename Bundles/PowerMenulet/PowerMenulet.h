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
	NSImage *p0, *p1, *p2, *p3, *p4, *p5;

	/* Cache */
	NSFileManager *fm;
}

- (NSView *) menuletView;

@end
