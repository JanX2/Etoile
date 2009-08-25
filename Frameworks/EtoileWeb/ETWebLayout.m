/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import <WebKit/WebKit.h>
#import "ETWebLayout.h"


@implementation ETWebLayout

- (ETLayout *) initWithLayoutView: (NSView *)view
{
	self = [super initWithLayoutView: nil];	
	if (self == nil)
		return nil;

	WebView *webView = [[WebView alloc] initWithFrame: NSMakeRect(0, 0, 200, 100)];
		
	[webView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[self setLayoutView: webView];
	RELEASE(webView);
	
	return self;
}

- (WebView *) webView
{
	return [self layoutView];
}

@end


@implementation WebView (Etoile)

- (BOOL) isWidget
{
	return YES;
}

@end
