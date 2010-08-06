/**
 * Étoilé ProjectManager - XCBSelection.m
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
#import "XCBSelection.h"

BOOL XCBAcquireManagerSelection(XCBScreen *screen, XCBWindow* managerWindow, xcb_atom_t atom, BOOL doReplace)
{
	xcb_get_selection_owner_cookie_t req  =
		xcb_get_selection_owner([XCBConn connection], atom);
	xcb_get_selection_owner_reply_t *resp =
		xcb_get_selection_owner_reply([XCBConn connection],
			req,
			NULL);
	xcb_window_t current_owner = resp->owner;
	free(resp);
	if (current_owner)
	{
		if (NO == doReplace)
		{
			return NO;
		}
		xcb_void_cookie_t req = xcb_destroy_window_checked([XCBConn connection], current_owner);
		if (xcb_request_check([XCBConn connection], req))
		{
			return NO;
		}
	}

	xcb_timestamp_t server_time = [XCBConn currentTime];

	xcb_void_cookie_t cookie = xcb_set_selection_owner_checked(
		[XCBConn connection],
		[managerWindow xcbWindowId],
		atom,
		server_time);
	xcb_generic_error_t *error = xcb_request_check([XCBConn connection], cookie);
	if (error)
	{
		NSDebugLLog(@"XCBSelection", @"XCBAcquireManagerSelection: SetSelectionOwner failed.");
		return NO;
	}
	return YES;
}
