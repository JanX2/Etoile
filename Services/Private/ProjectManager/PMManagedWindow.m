/**
 * Étoilé ProjectManager - PMManagedWindow.m
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
#import "PMManagedWindow.h"
#import "XCBWindow.h"
#import <EtoileFoundation/EtoileFoundation.h>

static const int DecorationWindowBorderSize = 4;

@interface PMManagedWindow (Private)
- (XCBRect)idealDecorationWindowFrame;
- (id)initWithChildWindow: (XCBWindow*)win;
- (void)unmapDecorationWindow;
@end

@implementation PMManagedWindow
- (id)initWithChildWindow: (XCBWindow*)win
{
	SELFINIT;
	child = [win retain];
	[child setDelegate: self];
	NSNotificationCenter *center =
		[NSNotificationCenter defaultCenter];

	XCBWindow *root = [child parent];
	NSLog(@"-[PMMangedWindow initWithChildWindow:] Root: %@", root);

	uint32_t values[3];
	// FIXME: Do these have to be in the same order as the
	// mask declarations?
	values[0] = 0x80FFFF10;
	values[1] = 1;
	values[2] = XCB_EVENT_MASK_EXPOSURE |
		XCB_EVENT_MASK_BUTTON_PRESS | 
		XCB_EVENT_MASK_BUTTON_RELEASE;
	decorationWindow = 
		[[root createChildInRect: [self idealDecorationWindowFrame]
		            borderWidth: 0
		             valuesMask: XCB_CW_BACK_PIXEL | XCB_CW_OVERRIDE_REDIRECT | XCB_CW_EVENT_MASK
		                 values: values
		                  depth: 0
		                  class: XCB_WINDOW_CLASS_INPUT_OUTPUT
		                 visual: 0] retain];
	[center addObserver: self
	           selector: @selector(decorationWindowCreated:)
	               name: XCBWindowBecomeAvailableNotification
	             object: decorationWindow];
	[center addObserver: self
	           selector: @selector(decorationWindowDidMap:)
	               name: XCBWindowDidMapNotification
	             object: decorationWindow];

	[XCBConn setNeedsFlush: YES];
	return self;
}
- (void) decorationWindowCreated: (NSNotification*)notification 
{
	NSLog(@"PMManagedWindow: decoration window become available.");
	if ([child mapState] == XCB_MAP_STATE_VIEWABLE)
		[self mapDecoratedWindow];
}
- (void)dealloc
{
	NSLog(@"-[PMManagedWindow dealloc]");
	NSNotificationCenter *center =
		[NSNotificationCenter defaultCenter];
	[center removeObserver: self];
	[child setDelegate: nil];
	[child release];
	[decorationWindow release];
	[super dealloc];
}
+ (PMManagedWindow*)windowDecoratingWindow: (XCBWindow*)win
{
	return [[[self alloc] initWithChildWindow: win] autorelease];
}
- (XCBRect)idealDecorationWindowFrame
{
	XCBRect frame = [child frame];
	// FIXME
	xcb_translate_coordinates_cookie_t c = xcb_translate_coordinates(
		[XCBConn connection], 
		[decorationWindow xcbWindowId], 
		[[decorationWindow parent] xcbWindowId],
		frame.origin.x,
		frame.origin.y);
	xcb_translate_coordinates_reply_t *r = xcb_translate_coordinates_reply(
		[XCBConn connection],
		c,
		NULL);
	if (r!=NULL) 
	{
		frame.origin.x = r->dst_x;
		frame.origin.y = r->dst_y;
		free(r);
	}
	// END FIXME
	frame.origin.x -= DecorationWindowBorderSize;
	frame.origin.y -= DecorationWindowBorderSize;
	frame.size.height += 2 * DecorationWindowBorderSize;
	frame.size.width += 2 * DecorationWindowBorderSize;
	return frame;
}
- (void)xcbWindowMapRequest: (NSNotification*)aNotification
{
	NSLog(@"-[PMManagedWindow xcbWindowDidMap:]");
	[self mapDecoratedWindow];
}
- (void)xcbWindowDidMap: (NSNotification*)notification
{
	NSLog(@"-[PMManagedWindow xcbWindowDidMap:] child window mapped.");
}
- (void)xcbWindowConfigureRequest: (NSNotification*)aNotification
{
	NSDictionary *values = [aNotification userInfo];
	uint32_t vl[7];
	int i = 0;
	
	XCBRect frame;
	NSInteger borderWidth, stackMode;
	id aboveWindow;
	NSInteger valueMask;

	valueMask = [[values objectForKey: @"ValueMask"] integerValue];
	NSLog(@"-[PMManagedWindow xcbWindowConfigureRequest:] valueMask=%d", valueMask);
	[[values objectForKey: @"Frame"] getValue: &frame];
	borderWidth = [[values objectForKey: @"BorderWidth"] integerValue];
	stackMode = [[values objectForKey: @"StackMode"] integerValue];
	aboveWindow = [values objectForKey: @"Above"];
	if ([aboveWindow isEqual: [NSNull null]])
		aboveWindow = nil;

	if (valueMask & XCB_CONFIG_WINDOW_X)
		vl[i++] = frame.origin.x;
	if (valueMask & XCB_CONFIG_WINDOW_Y)
		vl[i++] = frame.origin.y;
	if (valueMask & XCB_CONFIG_WINDOW_WIDTH)
		vl[i++] = frame.size.width;
	if (valueMask & XCB_CONFIG_WINDOW_HEIGHT)
		vl[i++] = frame.size.height;
	if (valueMask & XCB_CONFIG_WINDOW_BORDER_WIDTH)
		vl[i++] = borderWidth;
	if (valueMask & XCB_CONFIG_WINDOW_SIBLING)
		vl[i++] = [aboveWindow xcbWindowId];
	if (valueMask & XCB_CONFIG_WINDOW_STACK_MODE)
		vl[i++] = stackMode;
	
	// Just in case it contains other bit junk
	valueMask &= XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y |
		XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT |
		XCB_CONFIG_WINDOW_BORDER_WIDTH |
		XCB_CONFIG_WINDOW_SIBLING |
		XCB_CONFIG_WINDOW_STACK_MODE;
	[child configureWindow: valueMask
	                values: vl];
}
- (void)xcbWindowDidUnMap: (NSNotification*)aNotification
{
	if (!ignoreUnmap)
	{
		NSLog(@"Decorated window unmapped, removing decoration");
		[self unmapDecorationWindow];
	}
	ignoreUnmap = NO;
}
- (void)xcbWindowDidDestroy: (NSNotification*)aNotification
{
	NSLog(@"-[PMMangedWindow xcbWindowDidDestroy:] Child window destroyed.");
	// Destroy the decoration window but don't
	// release it yet
	[decorationWindow destroy];
}
- (void)xcbWindowFrameDidChange: (NSNotification*)aNotification
{
	NSLog(@"-[PMManagedWindow xcbWindowFrameDidChange]");
	XCBRect frame = [self idealDecorationWindowFrame];
	[[self decorationWindow] setFrame: frame];
}
- (XCBWindow*)decorationWindow
{
	return decorationWindow;
}
- (void)mapDecoratedWindow
{
	NSLog(@"PMManagedWindow: mapping the decoration window and then reparenting the child.");
	xcb_connection_t *conn = [[XCBConnection sharedConnection] connection];
	ignoreUnmap = YES;
	[child map];
	[child addToSaveSet];
	[[self decorationWindow] map];
	child_origin = [child frame].origin;
	[child reparentToWindow: decorationWindow
	                     dX: DecorationWindowBorderSize
	                     dY: DecorationWindowBorderSize];
	uint32_t value = XCB_EVENT_MASK_STRUCTURE_NOTIFY |
		XCB_EVENT_MASK_PROPERTY_CHANGE;
	[child changeWindowAttributes: XCB_CW_EVENT_MASK
	                       values: &value];
	
	[XCBConn setNeedsFlush: YES];
}
- (void)unmapDecorationWindow
{
	NSLog(@"PMManagedWindow: unmapping the decoration window and then unparenting the child.");
	[decorationWindow unmap];
	// FIXME: Should we calculate where it was before?
	[child reparentToWindow: [decorationWindow parent]
	                     dX: child_origin.x
	                     dY: child_origin.y];
}

- (void)decorationWindowDidMap: (NSNotification*)notification
{
	//ignoreUnmap = NO;
}
@end
