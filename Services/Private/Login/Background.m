#import <XWindowServerKit/XWindow.h>
#import "Background.h"

static Background* sharedInstance;

@interface BackView : NSView
{
	NSImage* image;
	NSAttributedString* string;
}

- (void) setImage: (NSImage*) image;
@end

@implementation BackView

- (void) setImage: (NSImage*) img
{
	ASSIGN (image, img);
}

- (void) dealloc
{
	DESTROY(image);
	[super dealloc];
}

- (void) drawRect: (NSRect) frame
{
	[[NSColor blackColor] set];
	NSRectFill (frame);

	if (image)
	{
		[image compositeToPoint: NSZeroPoint
			operation: NSCompositeSourceOver];
	}
}

@end

@implementation Background

- (void) set
{
	NSScreen* scr = [NSScreen mainScreen];
	NSWindow* win = [[NSWindow alloc] initWithContentRect: [scr frame]
		styleMask: NSBorderlessWindowMask backing: NSBackingStoreRetained defer: NO];
	view = [[BackView alloc] initWithFrame: [scr frame]];

	[win setContentView: view];

	NSFileManager* fm = [NSFileManager defaultManager];	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* path = [defaults stringForKey: @"ImagePath"];

	if (path)
	{
		if ([fm fileExistsAtPath: [path stringByStandardizingPath]])
		{
			NSImage* image = [[NSImage alloc] initWithContentsOfFile: path];
			[view setImage: [image autorelease]];
		}
	}

	[win makeKeyAndOrderFront: self];
	[win orderBack: self];
	[win setLevel: NSDesktopWindowLevel];
	[win display];

}

- (void) redraw
{
	[view setNeedsDisplay: YES];
}

- (void) setNeedsDisplayInRect: (NSRect) aRect
{
	[view setNeedsDisplayInRect: aRect];
}


+ (Background*) background
{
	if (sharedInstance == nil)
	{
		sharedInstance = [Background new];
	}
	return sharedInstance;
}

@end
