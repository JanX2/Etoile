#import "PMCompositeWindow.h"
#import <EtoileFoundation/EtoileFoundation.h>
#include <xcb/damage.h>
#include <xcb/render.h>
#include <xcb/composite.h>
#include <xcb/xcb_renderutil.h>

xcb_render_picture_t rootPicture;

@implementation PMCompositeWindow
- (PMCompositeWindow*)initWithXCBWindow: (XCBWindow*)aWindow
{
	SELFINIT;
	NSLog(@"Creating composite window");
	ASSIGN(window, aWindow);
	xcb_connection_t *conn = [XCBConn connection];
	xcb_window_t winID = [window xcbWindowId];

	const xcb_render_query_pict_formats_reply_t *formats = 
		xcb_render_util_query_formats(conn);
	xcb_render_pictvisual_t *visual =
		xcb_render_util_find_visual_format(formats, winID);

	xcb_render_pictforminfo_t *format = NULL;

	if (NULL != visual) 
	{
		xcb_render_pictforminfo_t template;
		template.id = visual->format;
		format = xcb_render_util_find_format(formats, XCB_PICT_FORMAT_ID, &template, 0);
	}
	else
	{
		format = xcb_render_util_find_standard_format(formats, XCB_PICT_STANDARD_RGB_24);
	}
	picture = xcb_generate_id(conn);
	uint32_t IncludeInferiors = 1;
	xcb_render_create_picture(conn, picture, winID, format->id,
			XCB_RENDER_CP_SUBWINDOW_MODE, &IncludeInferiors);
	root = rootPicture;
	return self;
}
+ (void)initialize
{
	xcb_connection_t *conn = [XCBConn connection];
	NSArray *screens = [XCBConn screens];
	// FIXME: Support multiple screens
	XCBScreen *screen = [screens objectAtIndex: 0];
	xcb_window_t rootID = [[screen rootWindow] xcbWindowId];


	/*
	xcb_composite_get_overlay_window_cookie_t cookie =
	   	xcb_composite_get_overlay_window(conn, rootID); 
	xcb_generic_error_t *error;
	xcb_composite_get_overlay_window_reply_t *reply =
		xcb_composite_get_overlay_window_reply(conn, cookie, &error);
	NSLog(@"Error: %x", error);
	overlayWindow = [[self alloc] initWithXCBWindow: [XCBWindow windowWithXCBWindow: reply->overlay_win]];
	NSLog(@"Overlay window: %@ (%d)", overlayWindow, reply->overlay_win);
	free(reply);
	*/

	rootPicture = xcb_generate_id(conn);

	const xcb_render_query_pict_formats_reply_t *formats = 
		xcb_render_util_query_formats(conn);

	xcb_render_pictforminfo_t *format = NULL;
	for(xcb_render_pictforminfo_iterator_t iter =
		   	xcb_render_query_pict_formats_formats_iterator(formats) ;
		iter.rem ;
	   	xcb_render_pictforminfo_next(&iter))
	{
		format = iter.data;
		if (format->depth == [screen screenInfo]->root_depth)
		{
			break;
		}
	}

	xcb_pixmap_t pixmap = xcb_generate_id(conn);

	uint32_t IncludeInferiors = 1;
	xcb_render_create_picture(conn, rootPicture, rootID, format->id, XCB_RENDER_CP_SUBWINDOW_MODE, &IncludeInferiors);
	/*
	xcb_void_cookie_t fillReply = 
	xcb_generic_error_t *err = xcb_request_check(conn, fillReply);
	NSLog(@"Error: %x", err);
	*/
	xcb_flush(conn);

	xcb_flush([XCBConn connection]);
}
+ (void)drawBackground
{
	NSArray *screens = [XCBConn screens];
	XCBScreen *screen = [screens objectAtIndex: 0];
	xcb_connection_t *conn = [XCBConn connection];
	[self clearClipRegion];
	//xcb_render_color_t white = {0xffff, 0xffff, 0xffff, 0xffff};
	xcb_render_color_t white = {0xafff, 0, 0xafff, 0xffff};
	xcb_screen_t *screenInfo = [screen screenInfo];
	xcb_rectangle_t rect = {0, 0, screenInfo->width_in_pixels, screenInfo->height_in_pixels};
	NSLog(@"Drawing rectangle in %x", rootPicture);
	xcb_render_fill_rectangles(conn, XCB_RENDER_PICT_OP_OVER, rootPicture, white, 1, &rect);
}
+ (void)clearClipRegion
{
	NSArray *screens = [XCBConn screens];
	XCBScreen *screen = [screens objectAtIndex: 0];
	xcb_connection_t *conn = [XCBConn connection];
	xcb_xfixes_region_t region = xcb_generate_id(conn);
	xcb_window_t rootID = [[screen rootWindow] xcbWindowId];
	xcb_xfixes_create_region_from_window(conn, region, rootID, 0);
	xcb_xfixes_set_picture_clip_region(conn, rootPicture, region, 0, 0);
	xcb_xfixes_destroy_region(conn, region);
}
// FIXME: Should be in a PMCompositeScreen class
+ (void)setClipRegionFromDamage: (struct xcb_damage_notify_event_t*)request
{
	xcb_connection_t *conn = [XCBConn connection];
	xcb_xfixes_region_t region = xcb_generate_id(conn);
	xcb_xfixes_create_region(conn, region, 0, NULL);
	xcb_xfixes_translate_region(conn, region, request->geometry.x,
			request->geometry.y);
	xcb_xfixes_set_picture_clip_region(conn, rootPicture, region, 0, 0);
	xcb_xfixes_destroy_region(conn, region);
}
+ (PMCompositeWindow*)compositeWindowWithXCBWindow: (XCBWindow*)aWindow
{
	return [[[self alloc] initWithXCBWindow: aWindow] autorelease];
}
- (void)setRootPicture: (xcb_render_picture_t)aPicture
{
	root = aPicture;
}
- (xcb_render_picture_t)picture
{
	return picture;
}
- (NSString*)description
{
	return [NSString stringWithFormat: @"<%@: %@>", [super description],
		   window];
}
- (void)drawXCBRect: (XCBRect)aRect
{
	XCBRect frame = [window frame];
	xcb_connection_t *conn = [XCBConn connection];
	NSLog(@"Drawing window %x into %x", picture, root);
	/*
	xcb_render_transform_t transform = {
	   	0x20000, 0, 0,
	   	0, 0x20000, 0,
		0, 0, 0x10000};
	xcb_render_set_picture_transform([XCBConn connection], picture, transform);
	xcb_render_fixed_t radius[] = {0x30000, 0x30000,
		0x10000,0x10000,0x10000,
		0x10000,0x40000,0x20000,
		0x10000,0x20000,0x10000};
	xcb_render_set_picture_filter(conn, picture, strlen("convolution"), "convolution", 6, radius);
	xcb_render_query_filters_cookie_t cookie = xcb_render_query_filters(conn, [window xcbWindowId]);
	xcb_render_query_filters_reply_t *reply = xcb_render_query_filters_reply(conn, cookie, NULL);
	xcb_str_iterator_t 	iter = xcb_render_query_filters_filters_iterator(reply);
	for (xcb_str_t *str = iter.data ; iter.rem ; xcb_str_next(&iter), str = iter.data) 
	{
		int len = xcb_str_name_length(str);
		char *buffer = malloc(len + 1);
		memcpy(buffer, xcb_str_name(str), len);
		buffer[len] = '\0';
		NSLog(@"Found filter: %s", buffer);
		free(buffer);
	}
	*/
	xcb_render_composite(conn, XCB_RENDER_PICT_OP_ATOP,
			picture, 0, rootPicture, 
			0, 0,
			0, 0,
			frame.origin.x, frame.origin.y, 
			frame.size.width, frame.size.height);
}
@end
