/**
 * Étoilé ProjectManager - XCBShape.h
 *
 * Copyright (C) 2010 Christopher Armstrong <carmstrong@fastmail.com.au>
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
#import "XCBShape.h"
#import "XCBExtension.h"

NSString* XCBWindowShapeNotifyNotification = @"XCBWindowShapeNotifyNotification";

@interface XCBConnection (XCBShape)
- (void)shapeNotify: (xcb_shape_notify_event_t*)event;
@end

@interface XCBWindow (XCBShape_Event)
- (void)handleShapeNotify: (xcb_shape_notify_event_t*)event;
@end

@implementation XCBShape
+ (void)initializeExtensionWithConnection: (XCBConnection*)connection;
{
	static const char *extensionName = "SHAPE";
	NSObject *delegate = [connection delegate];
	xcb_query_extension_reply_t* reply;
	
	reply = XCBInitializeExtension(
			connection,
			extensionName);

	xcb_shape_query_version_cookie_t version_cookie = 
		xcb_shape_query_version([connection connection]);
	xcb_shape_query_version_reply_t* version_reply = 
		xcb_shape_query_version_reply(
				[connection connection], version_cookie, NULL);
	if (!XCBCheckExtensionVersion(
				XCB_SHAPE_MAJOR_VERSION,
				XCB_SHAPE_MINOR_VERSION,
				version_reply->major_version,
				version_reply->minor_version))
	{
		free(reply);
		free(version_reply);
		[[NSException 
			exceptionWithName: XCBExtensionNotPresentException
			           reason: @"Unable to find the Shape extension with the version required."
			         userInfo: [NSDictionary dictionary]]
			raise];
	}
	NSLog(@"Initialized %s extension (%d.%d) for connection %@ ", 
		extensionName,
		version_reply->major_version,
		version_reply->minor_version,
		connection
		);

	[XCBConn setSelector: @selector(shapeNotify:) 
	           forXEvent: reply->first_event + XCB_SHAPE_NOTIFY];
	free(reply);
	free(version_reply);
}
@end

@implementation XCBWindow (XCBShape)

- (void)setShapeRectangles: (xcb_rectangle_t*)rects
                     count: (uint32_t)len
                  ordering: (uint8_t)ordering
                 operation: (xcb_shape_op_t)op
                      kind: (xcb_shape_kind_t)kind
                    offset: (XCBPoint)offset
{
	xcb_shape_rectangles([XCBConn connection],
		op,
		kind,
		ordering,
		[self xcbWindowId],
		offset.x,
		offset.y,
		len,
		rects);
}
- (void)setShapeSelectInput: (BOOL)selectShapeInput
{
	xcb_shape_select_input([XCBConn connection],
		[self xcbWindowId],
		selectShapeInput ? 1 : 0);
}
@end

@implementation XCBConnection (XCBShape)
- (void)shapeNotify: (xcb_shape_notify_event_t*)event
{
	XCBWindow *window = [XCBWindow windowWithXCBWindow: event->affected_window];
	[window handleShapeNotify: event];
}
@end

@implementation XCBWindow (XCBShape_Event)
- (void)handleShapeNotify: (xcb_shape_notify_event_t*)event
{
	// FIXME: Add event parameters to notification
	XCBDELEGATE(WindowShapeNotify);
	XCBNOTIFY(WindowShapeNotify);
}
@end
