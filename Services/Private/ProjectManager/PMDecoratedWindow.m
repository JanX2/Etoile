/**
 * Étoilé ProjectManager - PMDecoratedWindow.m
 *
 * Copyright (C) 2009 David Chisnall
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import "PMDecoratedWindow.h"
#import <EtoileFoundation/EtoileFoundation.h>

static const int DecorationWindowBorderSize = 4;

@interface PMDecoratedWindow (Private)
- (XCBRect)idealDecorationWindowFrame;
@end

@implementation PMDecoratedWindow
- (id)initDecoratingWindow: (XCBWindow*)win
{
	SELFINIT;
	window = [win retain];
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
	[center addObserver: self
	           selector: @selector(windowDidDestroy:)
	               name: XCBWindowDidDestroyNotification
	             object: window];

	XCBWindow *root = [window parent];
	NSLog(@"Root: %@", root);
	decorationWindow = 
		[root createChildInRect: [self idealDecorationWindowFrame]];

	// Register to receive map/unmap/destroy events from children of the
	// decoration window
	uint32_t events = XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY;
	xcb_change_window_attributes([XCBConn connection], 
			[decorationWindow xcbWindowId], XCB_CW_EVENT_MASK, &events);
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
	frame.origin.x -= DecorationWindowBorderSize;
	frame.origin.y -= DecorationWindowBorderSize;
	frame.size.height += 2 * DecorationWindowBorderSize;
	frame.size.width += 2 * DecorationWindowBorderSize;
	return frame;
}
- (void)windowDidUnMap: (NSNotification*)aNotification
{
	if (!ignoreUnmap)
	{
		NSLog(@"Decorated window unmapped, removing decoration");
		[decorationWindow unmap];
	}
	ignoreUnmap = NO;
}
- (void)windowDidDestroy: (NSNotification*)aNotification
{
	NSLog(@"Decorated window destroyed.");
	[decorationWindow destroy];
	DESTROY(decorationWindow);
	DESTROY(window);
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
	ignoreUnmap = YES;
	xcb_reparent_window(conn, [window xcbWindowId], winID,
			DecorationWindowBorderSize, DecorationWindowBorderSize);
	xcb_flush(conn);
	NSLog(@"Decorating window %d", winID);
}
@end
