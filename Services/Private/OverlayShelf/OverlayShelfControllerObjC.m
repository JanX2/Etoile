#import <AppKit/AppKit.h>
#import <EtoileUI/EtoileUI.h>
#import <CoreObject/CoreObject.h>

/*
 * Move to Smalltalk when NSRect works in Smalltalk under Linux
 */


@interface OverlayView : NSView
{
	NSImage *logo;
}
- (void) drawRect: (NSRect) rect;
- (id) init;
@end

@interface OverlayShelfPickboard : ETPickboard
@end
@implementation OverlayShelfPickboard
- (void) insertItem: (id) item atIndex: (int) index
{
	NSLog(@"insertItem:%@AtIndex:%d called", item, index);
}
@end


@interface OSFullscreenWindow : NSWindow
@end

@implementation OSFullscreenWindow

- (id) init
{

	self = [super initWithContentRect: [[NSScreen mainScreen] frame]
	                        styleMask: NSBorderlessWindowMask
	                          backing: NSBackingStoreBuffered
	                            defer: NO
	                           screen: [NSScreen mainScreen]];
	[self setLevel: NSScreenSaverWindowLevel];
	return self;
}

- (BOOL) canBecomeKeyWindow
{
	// Needed to accept mouse input.
	// See http://cocoadevcentral.com/articles/000028.php
	return YES;
}

@end


@interface OverlayShelfControllerObjC : NSObject
{
	NSMutableArray *images;
}
@end

@implementation OverlayShelfControllerObjC

- (id) init
{
	SUPERINIT;
	images = [[NSMutableArray alloc] init];
	[images addObject: [NSImage imageNamed:@"pic2"]];
	[images addObject: [NSImage imageNamed:@"pic1"]];
	return self;
}

- (NSWindow *) window
{
	NSWindow *win = [[OSFullscreenWindow alloc] init];

	[win setOpaque: NO];
	[win setBackgroundColor: [NSColor clearColor]];
	
	ETLayout *layout = [ETFreeLayout layout];
	ETContainer *container = [[ETContainer alloc] init];
	[container setLayout: layout];
	[container setSource: self];

	[win setContentView: [[OverlayView alloc] init]];
	[[win contentView] addSubview: container];
	[container setFrame: NSMakeRect(0,0,[win frame].size.width, [win frame].size.height)];

	[container reloadAndUpdateLayout];

	NSLog(@"layout context: %@", [[container layout] layoutContext]);
	NSLog(@"layout context items: %@", [[[container layout] layoutContext] items]);
	NSLog(@"layout context visible items: %@", [[[container layout] layoutContext] visibleItems]);

	return win;
}

- (NSImageView *) imageViewForImage: (NSImage *)image
{
	if (image != nil)
	{
		NSImageView *view = [[NSImageView alloc]
		    initWithFrame: NSMakeRect(0, 0, [image size].width, [image size].height)];
		[view setImage: image];
		return (NSImageView *)AUTORELEASE(view);
	}
	return nil;
}


/* ETContainerSource informal protocol */

- (int) numberOfItemsInContainer: (ETContainer *)container
{
	return [images count];
}

- (ETLayoutItem *) container: (ETContainer *)container itemAtIndex: (int)index
{
	NSImage *img = [images objectAtIndex: index];
	ETLayoutItem *imageItem = [ETLayoutItem layoutItemWithView: [self imageViewForImage: img]];
	NSValue *size = [NSValue valueWithSize: [img size]];
	[imageItem setValue: img forProperty: @"icon"];
	return imageItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
        return A(@"icon", @"size");
}

@end

@implementation OverlayView

- (void) drawRect: (NSRect) rect
{
	[super drawRect: rect];
	[self lockFocus];
	NSRectFillUsingOperation([self bounds], NSCompositeClear);

	NSColor *color = [NSColor colorWithDeviceRed: 0.0f green: 0.0f blue: 0.0f alpha: 0.7f];

	[color set];
	NSRectFillUsingOperation([self bounds], NSCompositeSourceOver);


	if (!logo)
	{
		logo = [[NSImage imageNamed: @"stamp"] retain];
	}

	NSSize size = [logo size];
	NSRect frame = [self frame];
	NSRect source = NSMakeRect(0, 0, size.width, size.height);
	NSRect dest = NSMakeRect((NSWidth(frame)/2) - (size.width/2), (NSHeight(frame)/2) - (size.height/2), size.width, size.height);


	[logo drawInRect: dest
	        fromRect: source
	       operation: NSCompositeSourceOver
	        fraction: 1.0f];

	[self unlockFocus];
}

- (id) init
{
	return [[OverlayView alloc] initWithFrame: [[NSScreen mainScreen] frame]];
}

@end
