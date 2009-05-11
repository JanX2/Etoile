#import "PMDecoratedWindow.h"
#import <EtoileFoundation/EtoileFoundation.h>

@interface PMDecoratedWindow (Private)
- (XCBRect)idealDecorationWindowFrame;
@end

@implementation PMDecoratedWindow
- (id)initDecoratingWindow: (XCBWindow*)win
{
	SELFINIT;
	ASSIGN(window, win);
	NSNotificationCenter *center =
		[NSNotificationCenter defaultCenter];
	[center addObserver: self
			   selector: @selector(windowFrameChanged:)
				   name: XCBWindowFrameDidChangeNotification
				 object: window];
	[center addObserver: self
			   selector: @selector(windowDidUnMap:)
				   name: XCBWindowDidUnMapNotification
				 object: window];

	XCBWindow *root = [window parent];
	NSLog(@"Root: %@", root);
	decorationWindow = 
		[root createChildInRect: [self idealDecorationWindowFrame]];
	return self;
}
- (void)dealloc
{
	NSNotificationCenter *center =
		[NSNotificationCenter defaultCenter];
	[center removeObserver: self];

	[window release];
	[decorationWindow release];
	[super dealloc];
}
+ (PMDecoratedWindow*)windowDecoratingWindow: (XCBWindow*)win
{
	return [[[self alloc] initDecoratingWindow: win] autorelease];
}
- (XCBRect)idealDecorationWindowFrame
{
	XCBRect frame = [window frame];
	frame.origin.x -= 3;
	frame.origin.y -= 3;
	frame.size.height += 6;
	frame.size.width += 6;
	return frame;
}
- (void)windowDidUnMap: (NSNotification*)aNotification
{
	[decorationWindow unmap];
}
- (void)windowFrameChanged: (NSNotification*)aNotification
{
	XCBRect frame = [self idealDecorationWindowFrame];
	[[self decorationWindow] setFrame: frame];
}
- (XCBWindow*)decorationWindow
{
	return decorationWindow;
}
- (void)mapDecoratedWindow
{
	xcb_connection_t *conn = [[XCBConnection sharedConnection] connection];
	xcb_window_t winID = [[self decorationWindow] xcbWindowId];
	xcb_map_window(conn, winID);
	xcb_reparent_window(conn, [window xcbWindowId], winID, 3,3);
	xcb_flush(conn);
	NSLog(@"Decorating window %d", winID);
}
@end
