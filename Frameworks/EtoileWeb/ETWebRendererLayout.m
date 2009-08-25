/*
 Copyright (C) 2009 Quentin Mathe
 
 Author:  Quentin Mathe <qmathe@club-internet.fr>
 Date:  July 2009
 License: Modified BSD (see COPYING)
 */

#import <WebKit/WebKit.h>
#import "ETWebLayout.h"
#import "ETWebRendererLayout.h"
#import "ETXHTMLRenderContext.h"


@implementation ETWebRendererLayout

- (ETLayout *) initWithLayoutView: (NSView *)view
{
	SUPERINIT;
	
	return self;
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
