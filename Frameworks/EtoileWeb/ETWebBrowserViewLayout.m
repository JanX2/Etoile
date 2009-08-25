/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  August 2009
 License:  Modified BSD  (see COPYING)
 */

#import <WebKit/WebKit.h>
#import <EtoileUI/ETCompatibility.h>
#import <EtoileFoundation/Macros.h>
#import "ETWebBrowserViewLayout.h"


@implementation ETWebBrowserViewLayout

- (id) init
{
	SUPERINIT;
	
	[[self webView] setFrameLoadDelegate: self];
	
	return self;
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[self setUpLayoutView];
	
	if ([items count] > 0)
	{
		id repObject = [[items objectAtIndex: 0] representedObject];
		if ([repObject isKindOfClass: [NSURL class]])
		{
			if (![[self currentURL] isEqual: repObject])
			{
				[[[self webView] mainFrame] loadRequest: [NSURLRequest requestWithURL: (NSURL *)repObject]];
			}
		}
	}
}

- (NSURL *) currentURL
{
	return [[[[[self webView] mainFrame] dataSource] initialRequest] URL];
}


/* WebKit FrameLoadDelegate methods */

- (void) webView: (WebView *)sender didStartProvisionalLoadForFrame: (WebFrame *)frame
{
    if (frame == [sender mainFrame])
	{
    }
}

- (void) webView: (WebView *)sender didReceiveTitle: (NSString *)title forFrame: (WebFrame *)frame
{
    if (frame == [sender mainFrame])
	{
    }
}

@end



