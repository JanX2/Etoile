#import "Player.h"
#import <X11/Xlib.h>
#import <GNUstepGUI/GSDisplayServer.h>

@implementation Player

- (void) resizeVideo: (NSSize) size
{
	NSSize c = [[window contentView] bounds].size;

	NSLog(@"resizeVideo %@", NSStringFromSize(size));

	c.width = size.width+10;
	c.height = size.height+60;
	if (c.width < 350) 
	{
		c.width = 350;
	}

	[window setContentSize: c];

	if (size.height > 0) 
	{
		XResizeWindow(dpy, contentView, size.width, size.height);
	} 
	else 
	{
		/* XWindow cannot be smaller than 1x1 */
		XResizeWindow(dpy, contentView, 1, 1);
	}
}

- (void) windowWillClose: (NSNotification *) not
{
	if (isPlaying == YES) 
	{
		[mmPlayer stop: self];
	}
}

- (void) volume: (id) sender
{
	[mmPlayer setVolumeInPercentage: [volumeSlider intValue]];
}

- (void) backwardAction: (id) sender
{
	NSLog(@"Backward");
}

- (void) play: (id) sender
{
	if (isPlaying == NO) 
	{
		// isPlaying = YES; // We set isPlaying only after receiving notification
    	[mmPlayer play: self];
	} 
	else 
	{
		// isPlaying = NO;
		[mmPlayer pause: self];
	}
}

- (void) forwardAction: (id) sender
{
	NSLog(@"Forward");
}

- (id) init
{
	self = [super init];

	if ([NSBundle loadNibNamed: @"Player" owner: self] == NO) 
	{
		[self dealloc];
		
		return nil;
	}

	return self;
}

- (void) awakeFromNib
{
	NSToolbar *toolbar = AUTORELEASE([[NSToolbar alloc] 
		initWithIdentifier: @"PlayerControls"]);
	int x, y, w, h;
	Window xwin = [window xwindow];
 
	dpy = [GSCurrentServer() serverDevice];

	/* Calculate frame for xwindow.
	   NOTE: In X window, origin is at top-left corner. */
	x = 0;
	y = [[window contentViewWithoutToolbar] frame].size.height + 17;
	w = [[window contentViewWithoutToolbar] frame].size.width;
	h = [[window contentViewWithoutToolbar] frame].size.height;

	contentView = XCreateSimpleWindow(dpy, xwin, x, y, w, h, 0, 0, 0);
	contentSize = NSMakeSize(w, h);
	
	XMapWindow(dpy, contentView);

	isPlaying = NO;

	[toolbar setDelegate: self];
	[window setToolbar: toolbar];

	[window makeKeyAndOrderFront: self];
}

/* Toolbar delegate methods */

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
		itemForItemIdentifier:(NSString*)identifier
		willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
	NSToolbarItem* toolbarItem = [[NSToolbarItem alloc] 
		initWithItemIdentifier: identifier];

	[toolbarItem setLabel: _(identifier)];
	[toolbarItem setTarget: self];
	[toolbarItem setEnabled: NO];

	if ([identifier isEqual: @"Play"]) 
	{
		[toolbarItem setImage: [NSImage imageNamed: @"play.tiff"]];
		[toolbarItem setAction: @selector(play:)];
	} 
	else if ([identifier isEqual: @"Back"]) 
	{
		[toolbarItem setImage: [NSImage imageNamed: @"bla"]];
		[toolbarItem setAction: @selector(back:)];
	} 
	else if ([identifier isEqual: @"Backward"]) 
	{
		[toolbarItem setImage: [NSImage imageNamed: @"bla"]];
		[toolbarItem setAction: @selector(backward:)];
	} 
	else if ([identifier isEqual: @"Forward"]) 
	{
		[toolbarItem setImage: [NSImage imageNamed: @"bla"]];
		[toolbarItem setAction: @selector(forward:)];
	} 
	else if ([identifier isEqual: @"Volume"]) 
	{
		[toolbarItem setTarget: nil];
		[toolbarItem setEnabled: YES];

		[volumeSlider removeFromSuperview];
		[volumeSlider setMaxValue: 100];
		[volumeSlider setMinValue: 0];
		[volumeSlider setAction: @selector(volume:)];
		[volumeSlider setTarget: self];
		[toolbarItem setView: volumeSlider];
	} 
	else if ([identifier isEqual: @"Fullscreen"]) 
	{
		[toolbarItem setImage: [NSImage imageNamed: @"etoile_back"]];
		[toolbarItem setAction: @selector(toggleFullscreen:)];
	} 
	else if ([identifier isEqual: @"Playlist"]) 
	{
		[toolbarItem setImage: [NSImage imageNamed: @"etoile_back"]];
		[toolbarItem setAction: @selector(togglePlaylistView:)];
	} 
	else 
	{
		NSAssert(@"Bad toolbar item requested: %@", identifier);
		DESTROY(toolbarItem);
	}
	
	NSAssert1(
		toolbarItem != nil,
		@"nil toolbar item returned for %@ identifier",
		identifier
	);

	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar 
{
	NSArray *identifiers = [NSArray arrayWithObjects: @"Volume", 
		NSToolbarFlexibleSpaceItemIdentifier, @"Back", @"Play",
		NSToolbarFlexibleSpaceItemIdentifier, @"Playlist", nil];

	return identifiers;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar 
{
	NSArray *identifiers = [NSArray arrayWithObjects: @"Play", @"Back", 
		@"Backward", @"Forward",  @"Volume", @"Fullscreen", 
		@"Playlist", NSToolbarSeparatorItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarFlexibleSpaceItemIdentifier, nil];

	return identifiers;
}


- (void) setPlayer: (id <MMPlayer>) player
{
	ASSIGN(mmPlayer, player);
	[mmPlayer setXWindow: contentView];
	[self resizeVideo: [mmPlayer size]];
	[volumeSlider setIntValue: [mmPlayer volumeInPercentage]];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(informationAvailable:)
		name: MMPlayerInformationAvailableNotification
		object: mmPlayer];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(playStatusChanged:)
		name: MMPlayerStartPlayingNotification
		object: mmPlayer];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(playStatusChanged:)
		name: MMPlayerPausedNotification
		object: mmPlayer];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(playStatusChanged:)
		name: MMPlayerStopNotification
		object: mmPlayer];
}

- (id <MMPlayer>) player
{
	return mmPlayer;
}

- (XWindow *) window
{
	return window;
}

/* Notification */
- (void) informationAvailable: (NSNotification *) not
{
	//[self resizeVideo: [mmPlayer size]];
}

- (void) playStatusChanged: (NSNotification *) not
{
	NSLog(@"%@", not);

	if ([[not name] isEqualToString: MMPlayerStartPlayingNotification]) 
	{
		isPlaying = YES;
		[playButton setImage: [NSImage imageNamed: @"pause.tiff"]];
		[self resizeVideo: [mmPlayer size]];
	} 
	else if ([[not name] isEqualToString: MMPlayerPausedNotification]) 
	{
		isPlaying = NO;
		[playButton setImage: [NSImage imageNamed: @"play.tiff"]];
	} 
	else if ([[not name] isEqualToString: MMPlayerStopNotification]) 
	{
		isPlaying = NO;
		[playButton setImage: [NSImage imageNamed: @"play.tiff"]];
	}
}

@end
