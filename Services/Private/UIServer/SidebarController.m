#import "SidebarController.h"
#import "UIServer.h"

@implementation SidebarController

- (void) activateProject: (id)sender
{
	ETLayoutItem *project = [[_sidebarGroup doubleClickedItem] representedObject];
	NSLog(@"Activate project: %@", project);
}

- (void) show
{
	ETUIItemFactory *factory = [ETUIItemFactory factory];

	NSWindow *win;
	win = [[NSWindow alloc] initWithContentRect: NSMakeRect(0.0, 0.0, 1.0, 1.0)
	                                  styleMask: [NSWindow defaultStyleMask]
	                                    backing: NSBackingStoreBuffered
	                                      defer: NO
	                                     screen: [NSScreen mainScreen]];
	[win setLevel: NSFloatingWindowLevel];
	//[win setOpaque: NO];
	//[win setBackgroundColor: [NSColor clearColor]];

	ETDecoratorItem *windowItem = [factory itemWithWindow: win];
		
	NSRect frame = [[NSScreen mainScreen] frame];
	frame.size.width = 200.0;
	frame.size.height -= 22.0; //FIXME: remove hack to accomodate menu bar


	_sidebarGroup = [[factory itemGroupWithRepresentedObject: [[UIServer server] rootGroup]] retain];
	[_sidebarGroup setSource: _sidebarGroup];
	[_sidebarGroup setFrame: frame];
	[_sidebarGroup setDecoratorItem: windowItem];
	[_sidebarGroup setLayout: [ETOutlineLayout layout]];
	[_sidebarGroup setDoubleAction: @selector(activateProject:)];
	[_sidebarGroup setDelegate: self];
	
	NSLog(@"root items: %@", [[[factory rootGroup] items] objectAtIndex: 0] );
}

- (id) init
{
	SUPERINIT;

	return self;
}

@end
