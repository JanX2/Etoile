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
#import <XCBKit/XCBSelection.h>
#import <XCBKit/XCBAtomCache.h>
#import <XCBKit/XCBWindow.h>
#import <EtoileFoundation/EtoileFoundation.h>

@interface XCBSelection (Private)
- (void)setOwner: (XCBWindow*)managerWindow;
@end

@implementation XCBSelection
- (id)initWithAtomNamed: (NSString*)atomName
{
	SELFINIT;
	atom = [[XCBAtomCache sharedInstance] atomNamed: atomName];
	return self;
}
- (id)initWithAtom: (xcb_atom_t)a
{
	SELFINIT;
	atom = a;
	return self;
}
- (BOOL)acquireWithManagerWindow: (XCBWindow*)managerWindow
                         replace: (BOOL)replace
{
	XCBWindow *currentOwner = [self requestOwner];
	if (nil != currentOwner)
	{
		if (!replace)
			return NO;
		[currentOwner waitForState: XCBWindowAvailableState];
		uint32_t events[1];
		events[0] = [currentOwner eventMask]| XCB_EVENT_MASK_STRUCTURE_NOTIFY;
		[currentOwner 
			changeWindowAttributes: XCB_CW_EVENT_MASK
			                values: events];

		[self setOwner: managerWindow];
		
		// Wait until the current owner is destroyed
		// because then we know we can continue
		if (!
			[currentOwner waitForState: XCBWindowDestroyedState
			                beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]])
		{
			// Forceibly destroy the window
			[currentOwner destroy];
			[currentOwner waitForState: XCBWindowDestroyedState];
		}
	}
	else
		[self setOwner: managerWindow];

	currentOwner = [self requestOwner];
	if ([currentOwner isEqual: managerWindow])
		return YES;
	else
		return NO;
}
- (void)setOwner: (XCBWindow*)managerWindow
{
	xcb_timestamp_t server_time = [XCBConn currentTime];

	xcb_set_selection_owner(
		[XCBConn connection],
		[managerWindow xcbWindowId],
		atom,
		server_time);
}
- (XCBWindow*)requestOwner
{
	xcb_get_selection_owner_cookie_t request = 
		xcb_get_selection_owner([XCBConn connection], atom);
	xcb_get_selection_owner_reply_t *reply = xcb_get_selection_owner_reply(
		[XCBConn connection],
		request,
		NULL);
	if (NULL == reply)
	{
		[NSException raise: NSGenericException
		            format: @"Unable to get the selection owner."];
	}
	XCBWindow *ownerWindow = reply->owner != XCB_NONE ?
		[XCBWindow windowWithXCBWindow: reply->owner] : (XCBWindow*)nil;
	free(reply);
	return ownerWindow;
}
- (xcb_atom_t)atom
{
	return atom;
}
@end
