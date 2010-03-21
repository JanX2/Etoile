/**
 * Étoilé ProjectManager - XCBComposite.m
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
#import "XCBComposite.h"
#import "XCBWindow.h"
#import "XCBExtension.h"
#import "XCBPixmap.h"

#include <xcb/composite.h>

@implementation XCBComposite
+ (void)initializeExtensionWithConnection: (XCBConnection*)connection
{
	static const char *extensionName = "Composite";
	NSObject *delegate = [connection delegate];
	xcb_query_extension_reply_t* reply;
	
	reply = XCBInitializeExtension(
			connection,
			extensionName);

	xcb_composite_query_version_cookie_t version_cookie = 
		xcb_composite_query_version([connection connection], 
			XCB_COMPOSITE_MAJOR_VERSION,
			XCB_COMPOSITE_MINOR_VERSION);
	xcb_composite_query_version_reply_t* version_reply = 
		xcb_composite_query_version_reply(
				[connection connection], version_cookie, NULL);
	if (!XCBCheckExtensionVersion(
				XCB_COMPOSITE_MAJOR_VERSION,
				XCB_COMPOSITE_MINOR_VERSION,
				version_reply->major_version,
				version_reply->minor_version))
	{
		free(reply);
		free(version_reply);
		[[NSException 
			exceptionWithName: XCBExtensionNotPresentException
			           reason: @"Unable to find the composite extension with the version required."
			         userInfo: [NSDictionary dictionary]]
			raise];
	}

	NSLog(@"Initialized %s extension (%d.%d) for connection %@ ", 
		extensionName,
		version_reply->major_version,
		version_reply->minor_version,
		connection
		);
	free(reply);
	free(version_reply);
}
+ (void) redirectSubwindows:(XCBWindow*)root method:(xcb_composite_redirect_t)method
{
	xcb_composite_redirect_subwindows([XCBConn connection], [root xcbWindowId], method);
}
+ (XCBPixmap*) nameWindowPixmap:(XCBWindow*)window
{
	XCBPixmap *pixmap = [[XCBPixmap alloc] initWithPixmapId:xcb_generate_id([XCBConn connection])];
	xcb_composite_name_window_pixmap([XCBConn connection], [window xcbWindowId], [pixmap xcbPixmapId]);
	return [pixmap autorelease];
}
@end
