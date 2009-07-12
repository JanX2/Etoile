/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import <WebKit/WebKit.h>
#import "ETWebLayout.h"
#import "ETXHTMLRenderContext.h"


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

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[self setUpLayoutView];

	NSString *xhtmlOutput = [ETXHTMLRenderContext render: [self layoutContext]];

	[[[self webView] mainFrame] loadHTMLString: xhtmlOutput baseURL: @""];
}

/*[ETEtoileUIRenderer rendererToXHTML]
ETEtoileUIBuilder builderFromAppKit
ETEtoileUIRenderer rendererFromAppKit
rendererToXTHML
ETEUIRenderer renderToXHTML:
renderFromAppKit:
renderFromAppKitWindow:
exportToXHTML: */

@end
