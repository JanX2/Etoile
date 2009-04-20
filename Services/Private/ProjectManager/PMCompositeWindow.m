#import "PMCompositeWindow.h"
#import <EtoileFoundation/EtoileFoundation.h>
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
	pixmap = xcb_generate_id(conn);
	xcb_window_t winID = [window xcbWindowId];
	xcb_composite_name_window_pixmap(conn, winID, pixmap);
	picture = xcb_generate_id(conn);

	const xcb_render_query_pict_formats_reply_t *formats = 
		xcb_render_util_query_formats(conn);
	xcb_render_pictvisual_t *visual =
		xcb_render_util_find_visual_format(formats, winID);

	xcb_render_pictforminfo_t *format;

	if (NULL != visual) 
	{
		xcb_render_pictforminfo_t template;
		template.id = visual->format;
		format = xcb_render_util_find_format(formats, XCB_PICT_FORMAT_ID, &template, 0);
	}
	xcb_render_create_picture(conn, picture, winID, format->id, 0, 0);
	root = rootPicture;
	return self;
}
+ (void)initialize
{
	xcb_connection_t *conn = [XCBConn connection];
	NSArray *screens = [XCBConn screens];
	// FIXME: Support multiple screens
	XCBScreen *screen = [screens objectAtIndex: 0];
	xcb_window_t win = [[screen rootWindow] xcbWindowId];
	/*
	xcb_composite_get_overlay_window_cookie_t cookie =
	   	xcb_composite_get_overlay_window(conn, win); 
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
	// FIXME:
	xcb_create_pixmap(conn, [screen screenInfo]->root_depth, pixmap, win, 1024, 768);

	uint32_t IncludeInferiors = 1;
	xcb_render_create_picture(conn, rootPicture, pixmap, format->id, XCB_RENDER_CP_SUBWINDOW_MODE, &IncludeInferiors);
	xcb_xfixes_region_t region = xcb_generate_id(conn);
	xcb_xfixes_create_region_from_window(conn, region, win, 0);
	xcb_xfixes_set_picture_clip_region(conn, rootPicture, region, 0, 0);

	xcb_flush(conn);

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
- (void)drawXCBRect: (XCBRect)aRect
{
	XCBRect frame = [window frame];
	xcb_connection_t *conn = [XCBConn connection];
	NSLog(@"Drawing window %x into %x", picture, root);
	xcb_render_composite([XCBConn connection], XCB_RENDER_PICT_OP_SRC,
		picture, 0, root, 0, 0, 0, 0, frame.origin.x, frame.origin.y,
		frame.size.width, frame.size.height);
	xcb_render_color_t red = {0xffff, 0, 0, 0xffff};
	xcb_rectangle_t rect = {0,0,500,500};
	NSLog(@"Drawing rectangle in %x", rootPicture);
	xcb_render_fill_rectangles([XCBConn connection], XCB_RENDER_PICT_OP_SRC, rootPicture, red, 1, &rect);
	xcb_flush([XCBConn connection]);
}
@end
