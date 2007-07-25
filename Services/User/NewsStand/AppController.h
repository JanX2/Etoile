//
//  AppController.h
//  Vienna
//
//  Created by Steve on Sat Jan 24 2004.
//  Copyright (c) 2007 Yen-Ju Chen. All rights reserved.
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

#import <AppKit/AppKit.h>
#import "Database.h"
#import "ArticleController.h"
#import "ActivityViewer.h"
#import "DownloadWindow.h"
#import "FolderView.h"

@class NewPreferenceController;
@class FoldersTree;
@class SmartFolder;
@class NewSubscription;
@class NewGroupFolder;
@class WebPreferences;
@class BrowserView;
@class ArticleListView;
@class UnifiedDisplayView;
@class EmptyTrashWarning;
@class ClickableProgressIndicator;

@interface AppController : NSObject 
{
	IBOutlet NSWindow *mainWindow;
	IBOutlet ArticleController *articleController;
	IBOutlet FoldersTree *foldersTree;
	IBOutlet FolderView *folderView;
	IBOutlet NSSplitView *splitView1;
	IBOutlet NSView *exportSaveAccessory;
	IBOutlet NSSearchField *searchView;
	IBOutlet ArticleListView *mainArticleView;
	IBOutlet UnifiedDisplayView *unifiedListView;
	IBOutlet NSView *articleFrame;
	IBOutlet NSButtonCell *exportAll;
	IBOutlet NSButtonCell *exportSelected;
	IBOutlet NSButton *exportWithGroups;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSTextField *statusText;
	IBOutlet ClickableProgressIndicator *spinner;
	IBOutlet NSMenuItem *sortByMenu;
	IBOutlet NSMenuItem *columnsMenu;
	IBOutlet NSMenuItem *stylesMenu;

	NSView<BaseView> *primaryView;
	ActivityViewer *activityViewer;
	NewPreferenceController *preferenceController;
	DownloadWindow *downloadWindow;
	SmartFolder *smartFolder;
	NewSubscription *rssFeed;
	NewGroupFolder *groupFolder;
	EmptyTrashWarning *emptyTrashWarning;
	// action for search field
	int searchMenuTag;
	
	Database *db;
	NSImage *originalIcon;
	int progressCount;
	NSDictionary *standardURLs;
	NSTimer *checkTimer;
	int lastCountOfUnread;
	BOOL isStatusBarVisible;
	NSString *persistedStatusText;
	BOOL didCompleteInitialisation;
}

// Menu action items
-(IBAction)showPreferencePanel:(id)sender;
-(IBAction)deleteMessage:(id)sender;
-(IBAction)deleteFolder:(id)sender;
-(IBAction)searchUsingToolbarTextField:(id)sender;
-(IBAction)markAllRead:(id)sender;
-(IBAction)markAllSubscriptionsRead:(id)sender;
-(IBAction)markRead:(id)sender;
-(IBAction)markFlagged:(id)sender;
-(IBAction)renameFolder:(id)sender;
-(IBAction)viewNextUnread:(id)sender;
-(IBAction)printDocument:(id)sender;
-(IBAction)toggleActivityViewer:(id)sender;
-(IBAction)goBack:(id)sender;
-(IBAction)goForward:(id)sender;
-(IBAction)newSmartFolder:(id)sender;
-(IBAction)newSubscription:(id)sender;
-(IBAction)newGroupFolder:(id)sender;
-(IBAction)editFolder:(id)sender;
-(IBAction)viewArticlePage:(id)sender;
-(IBAction)openWebElementInDefaultBrowser:(id)sender;
-(IBAction)viewSourceHomePage:(id)sender;
-(IBAction)emptyTrash:(id)sender;
-(IBAction)refreshAllFolderIcons:(id)sender;
-(IBAction)refreshSelectedSubscriptions:(id)sender;
-(IBAction)refreshAllSubscriptions:(id)sender;
-(IBAction)cancelAllRefreshes:(id)sender;
-(IBAction)showMainWindow:(id)sender;
-(IBAction)restoreMessage:(id)sender;
-(IBAction)skipFolder:(id)sender;
-(IBAction)showDownloadsWindow:(id)sender;
-(IBAction)conditionalShowDownloadsWindow:(id)sender;
#if 0 // NOT_USED
-(IBAction)changeFiltering:(id)sender;
#endif
-(IBAction)getInfo:(id)sender;
-(IBAction)unifiedLayout:(id)sender;
-(IBAction)reportLayout:(id)sender;
-(IBAction)condensedLayout:(id)sender;
-(IBAction)makeTextLarger:(id)sender;
-(IBAction)makeTextSmaller:(id)sender;
-(IBAction)downloadEnclosure:(id)sender;
-(IBAction)showHideStatusBar:(id)sender;
-(IBAction)unsubscribeFeed:(id)sender;
-(IBAction)setFocusToSearchField:(id)sender;

// Public functions
#if 0 // MAC_ONLY
-(void)installCustomEventHandler;
#endif
-(void)setStatusMessage:(NSString *)newStatusText persist:(BOOL)persistenceFlag;
-(NSArray *)contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems;
-(void)showUnreadCountOnApplicationIconAndWindowTitle;
-(void)openURLFromString:(NSString *)urlString inPreferredBrowser:(BOOL)openInPreferredBrowserFlag;
-(void)openURL:(NSURL *)url inPreferredBrowser:(BOOL)openInPreferredBrowserFlag;
-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(unsigned int)flags;
-(void)openURLInDefaultBrowser:(NSURL *)url;
-(void)selectFolder:(int)folderId;
-(void)createNewSubscription:(NSString *)url underFolder:(int)parentId afterChild:(int)predecessorId;
-(void)markSelectedFoldersRead:(NSArray *)arrayOfFolders;
-(void)doSafeInitialisation;
-(void)clearUndoStack;
-(NSString *)searchString;
-(void)setSearchString:(NSString *)newSearchString;
-(Article *)selectedArticle;
-(int)currentFolderId;
-(BOOL)isConnecting;
-(NSDictionary *)standardURLs;
-(NSView *)primaryView;
-(NSArray *)folders;
-(void)toggleOptionKeyButtonStates;
-(NSMenu *)folderMenu;
#ifndef GNUSTEP
-(void)viewAnimationCompleted:(NSView *)theView withTag:(int)viewTag;
#endif
@end
