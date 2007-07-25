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

#import <AppKit/AppKit.h>
#import <TRXML/TRXMLParserDelegate.h>

@class AppController;

@interface TextWebView: NSView <TRXMLParserDelegate> {
	AppController *controller;
	NSTextView *textView;
	NSScrollView *scrollView;
	BOOL openLinksInNewBrowser;
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
