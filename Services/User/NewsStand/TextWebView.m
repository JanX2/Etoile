//
//  TextWebView.m
//  Vienna
//
//  Created by Yen-Ju Chen on Tue Jul 18 2007.
//  Copyright (c) 2007 Yen-Ju Chen. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "TextWebView.h"
#import "AppController.h"
#import "Preferences.h"
#import "DownloadManager.h"
#import "StringExtensions.h"
#import "TRXML/TRXMLParser.h"

#if 0
@interface NSObject (TabbedWebViewDelegate)
	-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(unsigned int)flags;
@end
#endif

#if 0
@interface TabbedWebView (Private)
	-(BOOL)isDownloadFileType:(NSURL *)filename;
	-(void)loadMinimumFontSize;
	-(void)handleMinimumFontSizeChange:(NSNotification *)nc;
	-(void)loadUseJavaScript;
	-(void)handleUseJavaScript:(NSNotification *)nc;
@end
#endif

@implementation TextWebView

/* TRXMLParser Delegate */
- (void)characters:(NSString *)_chars
{
	[[textView textStorage] appendAttributedString: [[[NSAttributedString alloc] initWithString: _chars] autorelease]];
}

- (void)startElement:(NSString *)_Name
          attributes:(NSDictionary*)_attributes
{
}

- (void)endElement:(NSString *)_Name
{
}

- (void) setParser:(id) XMLParser
{
}

- (void) setParent:(id) newParent
{
}

/* initWithFrame
 * The designated instance initialiser.
 */
-(id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
		// Init our vars
		controller = nil;
		NSRect rect = NSZeroRect;
		rect.size = frameRect.size;
		scrollView = [[NSScrollView alloc] initWithFrame: rect];
		rect.size = [NSScrollView contentSizeForFrameSize: rect.size hasHorizontalScroller: NO hasVerticalScroller: NO borderType:NSBezelBorder];
		textView = [[NSTextView alloc] initWithFrame: rect];
	    [textView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[textView setEditable: NO];
		[textView setSelectable: YES];
		[scrollView setDocumentView: textView];
	    [scrollView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[scrollView setAutoresizesSubviews: YES];
		[scrollView setHasVerticalScroller: YES];
		[scrollView setAutohidesScrollers: YES];
		[scrollView setBorderType: NSBezelBorder];
		[self addSubview: scrollView];
		openLinksInNewBrowser = NO;
#if 0
	isFeedRedirect = NO;
	isDownload = NO;
#endif
	
	}
	return self;
}

/* setController
 * Set the associated controller for this view
 */
-(void)setController:(AppController *)theController
{
	[theController retain];
	[controller release];
	controller = theController;
}

-(void)setHTML:(NSString *)htmlText withBase:(NSString *)urlString
{
//	[textView setString: htmlText];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: self];
	[textView setString: @""];
	[[textView textStorage] beginEditing];
	[parser parseFromSource: htmlText];
	[[textView textStorage] endEditing];
}

/* setOpenLinksInNewBrowser
 * Specify whether links are opened in a new browser by default.
 */
-(void)setOpenLinksInNewBrowser:(BOOL)flag
{
	openLinksInNewBrowser = flag;
}

#if 0
/* setIsDownload
 * Specifies whether the current load is a file download.
 */
-(void)setIsDownload:(BOOL)flag
{
	isDownload = flag;
}

/* isDownload
 * Returns whether the current load is a file download.
 */
-(BOOL)isDownload
{
	return isDownload;
}

/* setIsFeedRedirect
 * Indicates that the current load has been redirected to a feed URL.
 */
-(void)setIsFeedRedirect:(BOOL)flag
{
	isFeedRedirect = flag;
}

/* isFeedRedirect
 * Specifies whether the current load was a redirect to a feed URL.
 */
-(BOOL)isFeedRedirect
{
	return isFeedRedirect;
}

/* isDownloadFileType
 * Given a URL, returns whether the URL represents a file that should be downloaded or
 * a link that should be displayed.
 */
-(BOOL)isDownloadFileType:(NSURL *)url
{
	NSString * newURLExtension = [[url path] pathExtension];
	return ([newURLExtension isEqualToString:@"dmg"] ||
			[newURLExtension isEqualToString:@"sit"] ||
			[newURLExtension isEqualToString:@"bin"] ||
			[newURLExtension isEqualToString:@"bz2"] ||
			[newURLExtension isEqualToString:@"exe"] ||
			[newURLExtension isEqualToString:@"sitx"] ||
			[newURLExtension isEqualToString:@"zip"] ||
			[newURLExtension isEqualToString:@"gz"] ||
			[newURLExtension isEqualToString:@"tar"]);
}
#endif

#if 0
/* handleMinimumFontSizeChange
 * Called when the minimum font size for articles is enabled or disabled, or changed.
 */
-(void)handleMinimumFontSizeChange:(NSNotification *)nc
{
	[self loadMinimumFontSize];
}

/* handleUseJavaScriptChange
 * Called when the user changes the 'Use Javascript' setting.
 */
-(void)handleUseJavaScriptChange:(NSNotification *)nc
{
	[self loadUseJavaScript];
}
#endif

#if 0 // FIXME
/* loadMinimumFontSize
 * Sets up the web preferences for a minimum font size.
 */
-(void)loadMinimumFontSize
{
	Preferences * prefs = [Preferences standardPreferences];
	if (![prefs enableMinimumFontSize])
		[defaultWebPrefs setMinimumFontSize:1];
	else
	{
		int size = [prefs minimumFontSize];
		[defaultWebPrefs setMinimumFontSize:size];
	}
}
#endif

#if 0
/* loadUseJavaScript
 * Sets up the web preferences for using JavaScript.
 */
-(void)loadUseJavaScript
{
	Preferences * prefs = [Preferences standardPreferences];
	[defaultWebPrefs setJavaScriptEnabled:[prefs useJavaScript]];
}
#endif

#if 0
/* keyDown
 * Here is where we handle special keys when the broswer view
 * has the focus so we can do custom things.
 */
-(void)keyDown:(NSEvent *)theEvent
{
	if ([[theEvent characters] length] == 1)
	{
		unichar keyChar = [[theEvent characters] characterAtIndex:0];
		if ((keyChar == NSLeftArrowFunctionKey) && ([theEvent modifierFlags] & NSCommandKeyMask))
		{
			[self goBack:self];
			return;
		}
		else if ((keyChar == NSRightArrowFunctionKey) && ([theEvent modifierFlags] & NSCommandKeyMask))
		{
			[self goForward:self];
			return;
		}
	}
	[super keyDown:theEvent];
}
#endif

/* printDocument
 * Print the active article.
 */
-(void)printDocument:(id)sender
{
#if 0
	NSView * printView = [[[self mainFrame] frameView] documentView];
	NSPrintInfo * printInfo = [NSPrintInfo sharedPrintInfo];
	
	NSMutableDictionary * dict = [printInfo dictionary];
	[dict setObject:[NSNumber numberWithFloat:36.0f] forKey:NSPrintLeftMargin];
	[dict setObject:[NSNumber numberWithFloat:36.0f] forKey:NSPrintRightMargin];
	[dict setObject:[NSNumber numberWithFloat:36.0f] forKey:NSPrintTopMargin];
	[dict setObject:[NSNumber numberWithFloat:36.0f] forKey:NSPrintBottomMargin];
	
	[printInfo setVerticallyCentered:NO];
	[printView print:self];
#endif
}

// Fake Web Kit
-(void)setUIDelegate: (id) anObject
{
}

-(void)setFrameLoadDelegate:(id)anObject
{
}

-(void)setMaintainsBackForwardList:(BOOL)flag
{
}

/* dealloc
 * Clean up behind ourself.
 */
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[controller release];
	[super dealloc];
}
@end
