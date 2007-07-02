#import <AppKit/AppKit.h>
#import "EtoileMenulet.h"
#import <SystemConfig/SCSound.h>

@interface VolumeControlMenulet : NSObject <EtoileMenulet>
{
	NSButton *view;
	NSTimer *timer;
	NSWindow *volumeControlWindow;
	NSSlider *slider;
	SCSound *sound;

	NSImage *v0, *v1, *v2, *v3;
}

- (NSView *) menuletView;

@end
