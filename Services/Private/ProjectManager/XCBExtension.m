/**
 * Étoilé ProjectManager - XCBExtension.m
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
#import "XCBExtension.h"
#import <Foundation/Foundation.h>

NSString* XCBExtensionNotPresentException = 
	@"XCBExtensionNotPresentException";

xcb_query_extension_reply_t* XCBInitializeExtension(XCBConnection* connection, const char* extensionName)
{
	xcb_query_extension_cookie_t cookie = xcb_query_extension(
			[connection connection],
			strlen(extensionName),
			extensionName);
	xcb_query_extension_reply_t *reply = 
		xcb_query_extension_reply([connection connection], cookie, NULL);
	if (!reply->present)
	{
		free(reply);
		@throw [NSException exceptionWithName:XCBExtensionNotPresentException
			reason:[NSString stringWithFormat:
				@"The %s extension is not present on the X server.",
				extensionName]
			userInfo:[NSDictionary dictionary]
			];
	}

	return reply;
}
BOOL XCBCheckExtensionVersion(int minMajor, int minMinor, int actualMajor, int actualMinor)
{
	if (actualMajor > minMajor)
		return YES;
	else if (actualMajor == minMajor &&
			actualMinor >= minMinor)
		return YES;
	else
		return NO;
}
