/**	<title>ETWebLayout</title>

	<abstract>A WebKit-based layout that renders the layout context into XHTML 
	before handling it to the WebKit view.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>


@interface ETWebLayout : ETLayout
{
	NSString *title;
}

@end
