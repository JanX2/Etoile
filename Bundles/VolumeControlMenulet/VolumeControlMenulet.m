#import "VolumeControlMenulet.h"
#import <SystemConfig/SCSound.h>

#define WIDTH 40
#define HEIGHT 150
#define PAD 5

@implementation VolumeControlMenulet
- (void) sliderAction: (id) sender
{
	if (slider == sender)
	{
		[sound setOutputVolume: [slider intValue]];
	}
}

- (void) buttonAction: (id) sender
{
	if (volumeControlWindow == nil) 
	{
		/* Try to get right position */
		int w = WIDTH;
		int h = HEIGHT;
		int y = NSMinY([[view window] frame])-h;
		int x = NSMinX([view frame]) + NSMinX([[view window] frame]);
		/* Make sure the window is inside the screen */
		x = (x+w > NSMaxX([[view window] frame])) ? NSMaxX([[view window] frame])-w : x;
		NSRect rect = NSMakeRect(x, y, w, h);
		volumeControlWindow = [[NSWindow alloc] initWithContentRect: rect
                                      styleMask: NSBorderlessWindowMask
                                        backing: NSBackingStoreRetained
                                          defer: NO];

		rect = NSMakeRect(PAD, PAD, WIDTH-2*PAD, HEIGHT-2*PAD);
		slider = [[NSSlider alloc] initWithFrame: rect];
		[slider setTarget: self];
		[slider setAction: @selector(sliderAction:)];
		[slider setMaxValue: 100];
		[slider setMinValue: 0];
		[[volumeControlWindow contentView] addSubview: slider];
		RELEASE(slider);
	}
	if ([volumeControlWindow isVisible]) 
	{
		[volumeControlWindow orderOut: self];
	}
	else 
	{
		[slider setIntValue: [sound outputVolume]];
		[slider setNeedsDisplay: YES];
		[volumeControlWindow makeKeyAndOrderFront: self];
	}
}

- (void) dealloc
{
	if (timer)
	{
		[timer invalidate];
		DESTROY(timer);
	}
	DESTROY(view);
	DESTROY(volumeControlWindow);
	[super dealloc];
}

- (id) init
{
	NSRect rect = NSZeroRect;

	self = [super init];

	rect.size.height = 22;
	rect.size.width = 50;
	view = [[NSButton alloc] initWithFrame: rect];
	[view setBordered: NO];
	[view setTitle: @"Volume"];
	[view setTarget: self];
	[view setAction: @selector(buttonAction:)];

	ASSIGN(sound, (SCSound *)[SCSound sharedInstance]);

#if 0 // Should we check volume once for a while ?
	/* Start timer for every 5 seconds */
	`ASSIGN(timer, [NSTimer scheduledTimerWithTimeInterval: 5
                         target: self
                         selector: @selector(checkPower:)
                         userInfo: nil
                         repeats: YES]);
	[self checkPower: timer];
#endif

  return self;
}

- (NSView *) menuletView
{
	return (NSView *)view;
}

@end
