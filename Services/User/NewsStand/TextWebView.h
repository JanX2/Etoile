//
//  TextWebView.h
//  Vienna
//
//  Created by Yen-Ju on Tue Jul 18 2007.
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

#define USE_TRXML_XHTML 1

#import <AppKit/AppKit.h>
#if USE_TRXML_XHTML
#else
#import <TRXML/TRXMLParserDelegate.h>
#endif

typedef enum _TextStyle {
	NoTextStyle = 0,
	TitleTextStyle,
	BodyTextStyle,
	DetailTextStyle
} TextStyle;

@class AppController;

#if USE_TRXML_XHTML
@interface TextWebView: NSView {
#else
@interface TextWebView: NSView <TRXMLParserDelegate> {
#endif
	AppController *controller;
	NSTextView *textView;
	NSScrollView *scrollView;
	BOOL openLinksInNewBrowser;

	NSFont *titleFont;
	NSFont *bodyFont;
	NSFont *detailFont;
	NSMutableDictionary *attributes;
	TextStyle textStyle;
	int fontSize;

	NSString *_htmlText;
	NSString *_urlString;
#if USE_TRXML_XHTML
#else
	int bold; // <b>, <em>, <strong>tag
	int italic; // <i>tag
	int link; // <a href> tag
#endif

#if 0
	BOOL isFeedRedirect;
	BOOL isDownload;
#endif
}

// Public functions
-(void)setController:(AppController *)theController;
-(void)setHTML:(NSString *)htmlText withBase:(NSString *)urlString;
-(void)setOpenLinksInNewBrowser:(BOOL)flag;
-(void)printDocument:(id)sender;

// Fake Web Kit
-(void)setUIDelegate: (id) anObject;
-(void)setFrameLoadDelegate:(id)anObject;
-(void)setMaintainsBackForwardList:(BOOL)flag;

- (void) makeTextLarger: (id) sender;
- (void) makeTextSmaller: (id) sender;

#if 0
-(void)keyDown:(NSEvent *)theEvent;
-(BOOL)isFeedRedirect;
-(BOOL)isDownload;
#endif
@end
