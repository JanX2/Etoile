#import "BackgroundController.h"

@implementation BackgroundController

- (id) init
{
	SUPERINIT;
	// FIXME: support multiple screens
	// FIXME: resize window if screen changes size (e.g. in a VM)
	_background = [[NSWindow alloc] initWithContentRect: [[NSScreen mainScreen] frame]
	                                          styleMask: NSBorderlessWindowMask
	                                            backing: NSBackingStoreBuffered
	                                              defer: NO
	                                             screen: [NSScreen mainScreen]];
	[_background setLevel: NSDesktopWindowLevel];
	return self;
}

@end
