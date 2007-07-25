//
//  BaseView.h
//  Vienna
//
//  Created by Steve on 5/6/06.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
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

@protocol BaseView
	- (void) performFindPanelAction: (int) tag;
	- (void) printDocument: (id) sender;
	- (void) handleGoForward: (id) sender;
	- (void) handleGoBack: (id) sender;
	- (BOOL) canGoForward;
	- (BOOL) canGoBack;
	- (NSView *) mainView;
	- (NSView *) webView;
	- (void) makeTextLarger: (id) sender;
	- (void) makeTextSmaller: (id) sender;
	- (BOOL) handleKeyDown: (unichar) keyChar withFlags: (unsigned int) flags;
@end
