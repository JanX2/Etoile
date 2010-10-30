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
#import <XCBKit/XCBShape.h>
#import <XCBKit/XCBExtension.h>

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
- (void)shapeCombineWithKind: (xcb_shape_kind_t)destKind
                   operation: (xcb_shape_op_t)op
                      offset: (XCBPoint)offset
                      source: (XCBWindow*)sourceWindow
                  sourceKind: (xcb_shape_kind_t)sourceKind
{
	xcb_shape_combine([XCBConn connection],
		op,
		destKind,
		sourceKind,
		[self xcbWindowId],
		offset.x,
		offset.y,
		[sourceWindow xcbWindowId]
		);
}
- (XCBShapeExtents)queryShapeExtents
{
	xcb_shape_query_extents_cookie_t cookie = 
		xcb_shape_query_extents([XCBConn connection], [self xcbWindowId]);
	xcb_generic_error_t *error;
	xcb_shape_query_extents_reply_t *reply =
		xcb_shape_query_extents_reply([XCBConn connection], cookie, &error);
	XCBShapeExtents extents = {};
	if (reply != NULL)
	{
		extents.boundingShaped = reply->bounding_shaped ? YES : NO;
		extents.clipShaped = reply->clip_shaped ? YES : NO;
		extents.boundingRect.origin.x = reply->bounding_shape_extents_x;
		extents.boundingRect.origin.y = reply->bounding_shape_extents_y;
		extents.boundingRect.size.width = reply->bounding_shape_extents_width;
		extents.boundingRect.size.height = reply->bounding_shape_extents_height;
		extents.clipRect.origin.x = reply->clip_shape_extents_x;
		extents.clipRect.origin.y = reply->clip_shape_extents_y;
		extents.clipRect.size.width = reply->clip_shape_extents_width;
		extents.clipRect.size.height = reply->clip_shape_extents_height;
		free(reply);
		return extents;
	}
	else
	{
		[XCBConn handleError: error];
		return extents;
	}
}
@end

@implementation XCBConnection (XCBShape)
- (void)shapeNotify: (xcb_shape_notify_event_t*)event
{
	XCBWindow *window = [XCBWindow windowWithXCBWindow: event->affected_window];
	// FIXME: Should the timestamp update our last server time
	// on XCBConnnection?
	[window handleShapeNotify: event];
}
@end

@implementation XCBWindow (XCBShape_Event)
- (void)handleShapeNotify: (xcb_shape_notify_event_t*)event
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger: event->shape_kind], @"Kind",
		[NSNumber numberWithBool: event->shaped], @"Shaped",
		[NSValue valueWithXCBRect: XCBMakeRect(event->extents_x, event->extents_y, event->extents_width, event->extents_height)], @"Region",
		[NSNumber numberWithUnsignedInteger: event->server_time], @"Timestamp",
		nil];
	XCBDELEGATE_U(WindowShapeNotify, userInfo);
	XCBNOTIFY_U(WindowShapeNotify, userInfo);
}
@end
