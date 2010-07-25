/**
 * Étoilé ProjectManager - main.m
 *
 * Copyright (C) 2009 David Chisnall
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

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSException.h>
#import "PMConnectionDelegate.h"

int main(const int argc, const char* argv[])
{
	PMConnectionDelegate *connectionDelegate = nil;
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	@try
	{
		connectionDelegate = [PMConnectionDelegate new];
		if (connectionDelegate == nil)
			return 1;
		[XCBConn startMessageLoop];
		//[[NSRunLoop currentRunLoop] run];
	}
	@catch (NSException* e)
	{
		NSLog(@"Aborted with exception: %@", e);
	}
	return 0;
}
