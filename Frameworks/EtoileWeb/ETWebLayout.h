/**	<title>ETWebLayout</title>

	<abstract>An abstract superclass for layouts which wrap a WebKit view.
	</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>
#import <WebKit/WebKit.h>

@interface ETWebLayout : ETLayout
{
}

- (WebView *)webView;

@end

@interface WebView (Etoile)

- (BOOL) isWidget;

@end