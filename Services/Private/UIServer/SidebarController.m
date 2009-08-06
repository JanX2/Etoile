#import "SidebarController.h"
#import "UIServer.h"

@implementation SidebarController

- (void) activateProject: (id)sender
{
	ETLayoutItem *project = [[_sidebarGroup doubleClickedItem] representedObject];
	NSLog(@"Activate project: %@", project);
}

- (id) init
{
	SUPERINIT;

	ETUIItemFactory *factory = [ETUIItemFactory factory];

	NSWindow *win;
	win = [[NSWindow alloc] initWithContentRect: NSMakeRect(0.0, 0.0, 1.0, 1.0)
	                                  styleMask: NSBorderlessWindowMask
	                                    backing: NSBackingStoreBuffered
	                                      defer: NO
	                                     screen: [NSScreen mainScreen]];
	[win setLevel: NSFloatingWindowLevel];
	[win setOpaque: NO];

	NSColor *purple = [NSColor colorWithCalibratedRed: 0.565 green: 0.463 blue: 0.702 alpha: 0.9];
	[win setBackgroundColor: purple];

	ETDecoratorItem *windowItem = [factory itemWithWindow: win];
		
	NSRect frame = [[NSScreen mainScreen] frame];
	frame.size.width = 200.0;
	frame.size.height -= 22.0; //FIXME: remove hack to accomodate menu bar

	_sidebarGroup = [[factory itemGroupWithRepresentedObject: [[UIServer server] rootGroup]] retain];
	[_sidebarGroup setSource: _sidebarGroup];
	[_sidebarGroup setFrame: frame];
	[_sidebarGroup setLayout: [ETStackLayout layout]];
	[_sidebarGroup setDoubleAction: @selector(activateProject:)];
	[_sidebarGroup setDelegate: self];
	
	[_sidebarGroup setDecoratorItem: windowItem];

	return self;
}

- (ETLayoutItemGroup *)sidebarGroup
{
	return _sidebarGroup;
}

@end
