#import "VolumeControlMenulet.h"
#import <SystemConfig/SCSound.h>

#define WIDTH 40
#define HEIGHT 150
#define PAD 5

@implementation VolumeControlMenulet
- (void) checkSound: (id) sender
{
	int volume = [sound outputVolume];
	NSImage *img = nil;
	if (volume < 1)
	{
		img = v0;
	}
	else if (volume < 36)
	{
		img = v1;
	}
	else if (volume < 71)
	{
		img = v2;
	}
	else if (volume < 101)
	{
		img = v3;
	}

	if (img == nil)
	{
		NSLog(@"Internal Error: Cannot get sound volume %d", volume);
	}
	[view setImage: img];
	[view setNeedsDisplay: YES];
}

- (void) sliderAction: (id) sender
{
	if (slider == sender)
	{
		[sound setOutputVolume: [slider intValue]];
		[self checkSound: self];
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
		[self checkSound: self];
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
	DESTROY(v0);
	DESTROY(v1);
	DESTROY(v2);
	DESTROY(v3);
	[super dealloc];
}

- (id) init
{
	NSRect rect = NSZeroRect;

	self = [super init];

	rect.size.height = 22;
	rect.size.width = 26;
	view = [[NSButton alloc] initWithFrame: rect];
	[view setImagePosition: NSImageOnly];
	[view setBordered: NO];
	[view setTitle: @"Volume"];
	[view setTarget: self];
	[view setAction: @selector(buttonAction:)];

	/* Cache image */
	NSBundle *bundle = [NSBundle bundleForClass: [self class]];
	NSString *path = nil;
	path = [bundle pathForResource: @"VolumeControl_0" ofType: @"tif"];
	if (path)
		v0 = [[NSImage alloc] initWithContentsOfFile: path];
	path = [bundle pathForResource: @"VolumeControl_1" ofType: @"tif"];
	if (path)
		v1 = [[NSImage alloc] initWithContentsOfFile: path];
	path = [bundle pathForResource: @"VolumeControl_2" ofType: @"tif"];
	if (path)
		v2 = [[NSImage alloc] initWithContentsOfFile: path];
	path = [bundle pathForResource: @"VolumeControl_3" ofType: @"tif"];
	if (path)
		v3 = [[NSImage alloc] initWithContentsOfFile: path];

	ASSIGN(sound, (SCSound *)[SCSound sharedInstance]);

#if 0 // Should we check volume once for a while ?
	/* Start timer for every 5 seconds */
	`ASSIGN(timer, [NSTimer scheduledTimerWithTimeInterval: 5
                         target: self
                         selector: @selector(checkSound:)
                         userInfo: nil
                         repeats: YES]);
#endif
	[self checkSound: self];

	return self;
}

- (NSView *) menuletView
{
	return (NSView *)view;
}

@end
