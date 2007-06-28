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
}

- (NSView *) menuletView;

@end
