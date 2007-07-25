//
//  AppController.m
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

#import "AppController.h"
#import "NewPreferencesController.h"
#import "FoldersTree.h"
#import "ArticleListView.h"
#import "UnifiedDisplayView.h"
#import "Import.h"
#import "Export.h"
#import "RefreshManager.h"
#import "StringExtensions.h"
#import "SplitViewExtensions.h"
#import "ViewExtensions.h"
#import "SearchFolder.h"
#import "NewSubscription.h"
#import "NewGroupFolder.h"
#import "ViennaApp.h"
#import "ActivityLog.h"
#import "Constants.h"
#import "ArticleView.h"
#import "EmptyTrashWarning.h"
#import "Preferences.h"
#import "InfoWindow.h"
#import "DownloadManager.h"
#import "HelperFunctions.h"
#if 0 // NOT_USED
#import "ToolbarItem.h"
#endif
#import "ClickableProgressIndicator.h"

@interface AppController (Private)
	- (NSMenu *) searchFieldMenu;
	- (void) handleFolderSelection:(NSNotification *)nc;
	- (void) handleCheckFrequencyChange:(NSNotification *)nc;
	- (void) handleFolderNameChange:(NSNotification *)nc;
	- (void) handleDidBecomeKeyWindow:(NSNotification *)nc;
	- (void) handleReloadPreferences:(NSNotification *)nc;
	- (void) handleShowStatusBar:(NSNotification *)nc;
	- (void) handleRefreshingProgress: (NSNotification *) nc;
	- (void) localiseMenus:(NSArray *)arrayOfMenus;
	- (void) updateNewArticlesNotification;
	- (void) initSortMenu;
	- (void) initColumnsMenu;
	- (void) initStylesMenu;
	- (void) startProgressIndicator;
	- (void) stopProgressIndicator;
	- (void) doEditFolder:(Folder *)folder;
	- (void) refreshOnTimer:(NSTimer *)aTimer;
	- (void) setStatusBarState:(BOOL)isVisible withAnimation:(BOOL)doAnimate;
	- (void) doConfirmedDelete:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
	- (void) doConfirmedEmptyTrash:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
	- (void) setImageForMenuCommand:(NSImage *)image forAction:(SEL)sel;
	- (NSString *) appName;
	- (void) setLayout:(int)newLayout withRefresh:(BOOL)refreshFlag;
	- (void) updateSearchPlaceholder;
	- (void) toggleOptionKeyButtonStates;
	- (FoldersTree *) foldersTree;
	- (BOOL) isStatusBarVisible;
	- (NSTimer *) checkTimer;
	- (NSToolbarItem *) toolbarItemWithIdentifier:(NSString *)theIdentifier;
 
	- (void) buildMainMenu;
	- (void) buildMainWindow;
	- (void) buildMainArticleView;
	- (void) buildUnifiedDisplayView;
	- (void) searchMenuAction: (id) sender;
@end

// Static constant strings that are typically never tweaked
static const int MA_Minimum_Folder_Pane_Width = 80;
static const int MA_Minimum_BrowserView_Pane_Width = 200;
static const int MA_StatusBarHeight = 22;

@implementation AppController

/* init
 * Class instance initialisation.
 */
-(id)init
{
	if ((self = [super init]) != nil)
	{
		progressCount = 0;
		persistedStatusText = nil;
		lastCountOfUnread = 0;
		isStatusBarVisible = YES;
		checkTimer = nil;
		didCompleteInitialisation = NO;
		emptyTrashWarning = nil;
	}
	return self;
}

/* awakeFromNib
 * Do all the stuff that only makes sense after our NIB has been loaded and connected.
 */
-(void)awakeFromNib
{
	[self buildMainWindow];
	articleController = [[ArticleController alloc] init];
	foldersTree = [[FoldersTree alloc] init];
	[articleController setFoldersTree: foldersTree];
	[foldersTree setFolderView: folderView];
	[foldersTree setAppController: self];
	[foldersTree awakeFromNib];
	Preferences * prefs = [Preferences standardPreferences];
#if 0 // MAC_ONLY
	[self installCustomEventHandler];
#endif
	
	// Restore the most recent layout
	[self setLayout:[prefs layout] withRefresh:NO];

	// Localise the menus
	[self localiseMenus:[[NSApp mainMenu] itemArray]];

	[mainWindow setTitle:[self appName]];

	// Register a bunch of notifications
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleFolderSelection:) name: MA_Notify_FolderSelectionChange object:nil];
	[nc addObserver:self selector:@selector(handleCheckFrequencyChange:) name: MA_Notify_CheckFrequencyChange object:nil];
	[nc addObserver:self selector:@selector(handleEditFolder:) name: MA_Notify_EditFolder object:nil];
	[nc addObserver:self selector:@selector(handleRefreshStatusChange:) name: MA_Notify_RefreshStatus object:nil];
	[nc addObserver:self selector:@selector(handleFolderNameChange:) name: MA_Notify_FolderNameChanged object:nil];
	[nc addObserver:self selector:@selector(handleDidBecomeKeyWindow:) name: NSWindowDidBecomeKeyNotification object:nil];
	[nc addObserver:self selector:@selector(handleReloadPreferences:) name: MA_Notify_PreferenceChange object:nil];
	[nc addObserver:self selector:@selector(handleShowStatusBar:) name: MA_Notify_StatusBarChanged object:nil];
	[nc addObserver:self selector: @selector(handleRefreshingProgress:) name: MA_Notify_Refreshing_Progress object: nil];

	// Init the progress counter and status bar.
	[self setStatusMessage:nil persist:NO];
	
	// Initialize the database
	if ((db = [Database sharedDatabase]) == nil)
	{
		[NSApp terminate:nil];
		return;
	}

	// Create search field programmingly */
	searchField = [[NSSearchField alloc] initWithFrame: NSMakeRect(0, 0, 200, 22)];
	[searchField setDelegate: self];
	[searchField setTarget: self];
	[searchField setAction: @selector(searchUsingToolbarTextField:)];
	searchView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 22)];
	[searchView addSubview: searchField];
	[searchField release];
	// SearchView is released in -dealloc
	
	// Create the toolbar.
	NSToolbar * toolbar = [[[NSToolbar alloc] initWithIdentifier:@"MA_Toolbar"] autorelease];

	// Set the appropriate toolbar options. We are the delegate, customization is allowed,
	// changes made by the user are automatically saved and we start in icon mode.
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES]; 
	[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[mainWindow setToolbar:toolbar];

	// Run the auto-expire now
	[db purgeArticlesOlderThanDays:[prefs autoExpireDuration]];
	
	// Preload dictionary of standard URLs
	NSString * pathToPList = [[NSBundle mainBundle] pathForResource:@"StandardURLs.plist" ofType:@""];
	if (pathToPList != nil)
		standardURLs = [[NSDictionary dictionaryWithContentsOfFile:pathToPList] retain];
	
	// Initialize the Styles, Sort By and Columns menu
	[self initSortMenu];
	[self initColumnsMenu];
	[self initStylesMenu];

	// Restore the splitview layout
	[splitView1 setLayout:[[Preferences standardPreferences] objectForKey:@"SplitView1Positions"]];	
	
	// Show the current unread count on the app icon
	originalIcon = [[NSApp applicationIconImage] copy];
	[self showUnreadCountOnApplicationIconAndWindowTitle];
	
	// Create a menu for the search field
	// The menu title doesn't appear anywhere so we don't localise it. 
	// The titles of each item is localised though.	
	searchMenuTag = MA_Search_All;
	[[searchField cell] setSearchMenuTemplate:[self searchFieldMenu]];

#ifndef GNUSTEP
	// Set the placeholder string for the global search field
	[[searchField cell] setPlaceholderString:NSLocalizedString(@"Search all articles", nil)];
#endif

	// Show/hide the status bar based on the last session state
	[self setStatusBarState:[prefs showStatusBar] withAnimation:NO];

	// Start the check timer
	[self handleCheckFrequencyChange:nil];
	
	// Do safe initialisation. 	 
	[self doSafeInitialisation];
}

- (void) buildMainMenu
{
#ifdef GNUSTEP
	NSMenu *menu = [[[NSMenu alloc] initWithTitle: _(@"NewsStand")] autorelease];
	
	/* Info */
	NSMenu *submenu = [[[NSMenu alloc] initWithTitle: _(@"Info")] autorelease];
	id <NSMenuItem> item = [menu addItemWithTitle: _(@"Info")
	                                       action: NULL
	                                keyEquivalent: @""];
	[submenu addItemWithTitle: @"Info..."
	                   action: @selector(orderFrontStandardInfoPanel:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: @"Preferences..."
	                   action: @selector(showPreferencePanel:)
	            keyEquivalent: @""];
	[item setSubmenu: submenu];
	
	/* File */
	submenu = [[[NSMenu alloc] initWithTitle: _(@"File")] autorelease];
	item = [menu addItemWithTitle: _(@"File")
	                       action: NULL
	                keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"New Subscription...")
	                   action: @selector(newSubscription:)
	            keyEquivalent: @"n"];
	[submenu addItemWithTitle: _(@"New Smart Folder...")
	                   action: @selector(newSmartFolder:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"New Group Folder...")
	                   action: @selector(newGroupFolder:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Refresh All Subscriptions")
	                   action: @selector(refreshAllSubscriptions:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Refresh Selected Subscriptions")
	                   action: @selector(refreshSelectedSubscriptions:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Refresh Folder Images")
	                   action: @selector(refreshAllFolderIcons:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Stop Refreshing")
	                   action: @selector(cancelAllRefreshes:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Import Subscriptions")
	                   action: @selector(importSubscriptions:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Export Subscriptions")
	                   action: @selector(exportSubscriptions:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Unsubscribe")
	                   action: @selector(unsubscribeFeed:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Get Info...")
	                   action: @selector(getInfo:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Empty Trash")
	                   action: @selector(emptyTrash:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Print...")
	                   action: @selector(printDocument:)
	            keyEquivalent: @""];
	[item setSubmenu: submenu];

	/* Edit */
	submenu = [[[NSMenu alloc] initWithTitle: _(@"Edit")] autorelease];
	item = [menu addItemWithTitle: _(@"Edit")
	                       action: NULL
	                keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Cut")
	                   action: @selector(cut:)
	            keyEquivalent: @"x"];
	[submenu addItemWithTitle: _(@"Copy")
	                   action: @selector(copy:)
	            keyEquivalent: @"c"];
	[submenu addItemWithTitle: _(@"Paste")
	                   action: @selector(paste:)
	            keyEquivalent: @"v"];
	[submenu addItemWithTitle: _(@"Delete")
	                   action: @selector(delete:)
	            keyEquivalent: @"v"];
	[submenu addItemWithTitle: _(@"Select All")
	                   action: @selector(selectAll:)
	            keyEquivalent: @"A"];
	[item setSubmenu: submenu];

	/* View */
	NSMenu *sm = nil;
	NSMenuItem *it = nil;
	submenu = [[[NSMenu alloc] initWithTitle: _(@"View")] autorelease];
	item = [menu addItemWithTitle: _(@"View")
	                       action: NULL
	                keyEquivalent: @""];
	sm = [[[NSMenu alloc] initWithTitle: _(@"Columns")] autorelease];
	columnsMenu = [submenu addItemWithTitle: _(@"Columns")
	                                 action: NULL
	                          keyEquivalent: @""];
	[columnsMenu setSubmenu: sm];
	sm = [[[NSMenu alloc] initWithTitle: _(@"Sort By")] autorelease];
	sortByMenu = [submenu addItemWithTitle: _(@"Sort By")
	                                 action: NULL
	                          keyEquivalent: @""];
	[sortByMenu setSubmenu: sm];
	[submenu addItemWithTitle: _(@"Next Unread")
	                   action: @selector(viewNextUnread:)
	            keyEquivalent: @"u"];
	sm = [[[NSMenu alloc] initWithTitle: _(@"Layout")] autorelease];
	[sm addItemWithTitle: _(@"Report")
	              action: @selector(reportLayout:)
	       keyEquivalent: @""];
	[sm addItemWithTitle: _(@"Condensed")
	              action: @selector(condensedLayout:)
	       keyEquivalent: @""];
	[sm addItemWithTitle: _(@"Unified")
	              action: @selector(unifiedLayout:)
	       keyEquivalent: @""];
	it = [submenu addItemWithTitle: _(@"Layout")
	                                 action: NULL
	                          keyEquivalent: @""];
	[it setSubmenu: sm];
	[submenu addItemWithTitle: _(@"Bigger Text")
	                   action: @selector(makeTextLarger:)
	            keyEquivalent: @"+"];
	[submenu addItemWithTitle: _(@"Smaller Text")
	                   action: @selector(makeTextSmaller:)
	            keyEquivalent: @"-"];
	[submenu addItemWithTitle: _(@"Back")
	                   action: @selector(goBack:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Forward")
	                   action: @selector(goForward:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Hide Status Bar")
	                   action: @selector(showHideStatusBar:)
	            keyEquivalent: @"/"];
	[item setSubmenu: submenu];

	/* Folder */
	submenu = [[[NSMenu alloc] initWithTitle: _(@"Folder")] autorelease];
	item = [menu addItemWithTitle: _(@"Folder")
	                       action: NULL
	                keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Search Articles")
	                   action: @selector(setFocusToSearchField:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Edit...")
	                   action: @selector(editFolder:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Delete...")
	                   action: @selector(deleteFolder:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Rename...")
	                   action: @selector(renameFolder:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Skip Folder")
	                   action: @selector(skipFolder:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Mark All Articles as Read")
	                   action: @selector(markAllRead:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Mark All Subscriptions as Read")
	                   action: @selector(markAllSubscriptionsRead:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Open Subscription Home Page")
	                   action: @selector(viewSourceHomePage:)
	            keyEquivalent: @""];
	[item setSubmenu: submenu];

	/* Articles */
	submenu = [[[NSMenu alloc] initWithTitle: _(@"Article")] autorelease];
	item = [menu addItemWithTitle: _(@"Article")
	                       action: NULL
	                keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Mark Read")
	                   action: @selector(markRead:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Mark Flagged")
	                   action: @selector(markFlagged:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Delete Article")
	                   action: @selector(deleteMessage:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Restore Article")
	                   action: @selector(restoreMessage:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Open Article Page")
	                   action: @selector(viewArticlePage:)
	            keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Download Enclosure")
	                   action: @selector(downloadEnclosure:)
	            keyEquivalent: @""];
	[item setSubmenu: submenu];

	/* Windows */
	submenu = [[[NSMenu alloc] initWithTitle: _(@"Windows")] autorelease];
	item = [menu addItemWithTitle: _(@"Windows")
	                       action: NULL
	                keyEquivalent: @""];
	[submenu addItemWithTitle: _(@"Activity Viewer")
	                   action: @selector(toggleActivityViewer:)
	            keyEquivalent: @"0"];
	[submenu addItemWithTitle: _(@"Main Window")
	                   action: @selector(showMainWindow:)
	            keyEquivalent: @"1"];
	[submenu addItemWithTitle: _(@"Downloads")
	                   action: @selector(showDownloadsWindow:)
	            keyEquivalent: @"3"];
	[submenu addItemWithTitle: _(@"Close Window")
	                   action: @selector(orderOut:)
	            keyEquivalent: @"w"];
	[item setSubmenu: submenu];

	[menu addItemWithTitle: @"Hide"
	                action: @selector(hide:)
	         keyEquivalent: @"h"];
	[menu addItemWithTitle: @"Quit"
	                action: @selector(terminate:)
	         keyEquivalent: @"q"];
	[NSApp setMainMenu: menu];
#if 0
-(IBAction)changeFiltering:(id)sender;
#endif

#endif
}

- (void) buildMainWindow
{
	NSRect rect = NSMakeRect(200, 200, 400, 300);;
	mainWindow = [[NSWindow alloc] initWithContentRect: rect
                     styleMask: NSTitledWindowMask |
	                            NSClosableWindowMask |
	                            NSResizableWindowMask
                     backing: NSBackingStoreBuffered
                     defer: NO];
	[mainWindow setFrameAutosaveName: @"mainWindow"];
	[mainWindow setTitle: @"NewsStand"];
	[mainWindow setDelegate: self];
	[mainWindow setReleasedWhenClosed: NO];
	rect = [[mainWindow contentView] bounds];
	rect.size.height -= 20;
	rect.origin.y += 20;
	splitView1 = [[NSSplitView alloc] initWithFrame: rect];
	[splitView1 setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	[splitView1 setVertical: YES];
	[splitView1 setDelegate:self];

	rect = [splitView1 bounds];
	rect.size.width = rect.size.width/4;
	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame: rect];
	[scrollView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	[scrollView setBorderType: NSBezelBorder];
	[scrollView setHasVerticalScroller: YES];
	[scrollView setAutohidesScrollers: YES];
	rect.size = [NSScrollView contentSizeForFrameSize: rect.size hasHorizontalScroller: NO hasVerticalScroller: NO borderType: NSBezelBorder];
	folderView = [[FolderView alloc] initWithFrame: rect];
	[folderView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: @"folderColumns"];
	[[column headerCell] setStringValue: @"Folders"];
	[folderView addTableColumn: column];
	[folderView setOutlineTableColumn: column];
	[folderView setAutosaveName: @"outViewer"];
	[folderView setAllowsMultipleSelection: YES];
	[folderView setAllowsEmptySelection: YES];
	[scrollView setDocumentView: folderView];
	[splitView1 addSubview: scrollView];
	[[mainWindow contentView] addSubview: splitView1];
	[scrollView release];
	[folderView release];
	[splitView1 release];
	[column release];

	rect.size.width = rect.size.width*3;
	articleFrame = [[NSView alloc] initWithFrame: rect];
	[articleFrame setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	[splitView1 addSubview: articleFrame];
	[articleFrame release];

	[folderView sizeLastColumnToFit];
	[folderView awakeFromNib];

	rect = [[mainWindow contentView] bounds];
	rect.origin.x = 5;
	rect.origin.y = 5;
	rect.size.height = 10;
	rect.size.width = rect.size.width/4-5*2;
	spinner = [[ClickableProgressIndicator alloc] initWithFrame: rect];
//	[spinner setAutoresizingMask: NSViewWidthSizable|NSViewMaxYMargin];
	[spinner setAutoresizingMask: NSViewMaxXMargin|NSViewMaxYMargin];
	[spinner setTarget:self];
	[spinner setAction:@selector(toggleActivityViewer:)];
	[spinner setMinValue: 0];
	[spinner setIndeterminate: NO];
	[[mainWindow contentView] addSubview: spinner];
	[spinner release];

	rect = [[mainWindow contentView] bounds];
	rect.origin.x = rect.size.width/4;
	rect.size.width = rect.size.width/2;
	rect.origin.y = 3;
	rect.size.height = 14;
	statusText = [[NSTextField alloc] initWithFrame: rect];
	[statusText setAutoresizingMask: NSViewWidthSizable|NSViewMaxYMargin];
	[statusText setStringValue: @"No New Articles"];
	[statusText setEditable: NO];
	[statusText setSelectable: NO];
	[statusText setBordered: NO];
	[statusText setFont: [NSFont controlContentFontOfSize: 10]];
	[statusText setAlignment: NSCenterTextAlignment];
	[[mainWindow contentView] addSubview: statusText];
	[statusText release];
}

- (void) buildMainArticleView
{
	mainArticleView = [[ArticleListView alloc] initWithFrame: NSMakeRect(0, 0, 200, 200)];
	[mainArticleView setController: self];
	[mainArticleView setArticleController: articleController];
	[mainArticleView setFoldersTree: foldersTree];
	[mainArticleView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	[mainArticleView awakeFromNib];
}

- (void)buildUnifiedDisplayView
{
	unifiedListView = [[UnifiedDisplayView alloc] initWithFrame: NSMakeRect(0, 0, 200, 200)];
	[unifiedListView setController: self];
	[unifiedListView setArticleController: articleController];
	[unifiedListView setFoldersTree: foldersTree];
	[unifiedListView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	[unifiedListView awakeFromNib];
}

#if 0 // MAC_ONLY
/* installCustomEventHandler
 * This is our custom event handler that tells us when a modifier key is pressed
 * or released anywhere in the system. Needed for iTunes-like button. The other 
 * half of the magic happens in ViennaApp.
 */
-(void)installCustomEventHandler
{
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventRawKeyModifiersChanged;

	EventHandlerUPP handlerFunction = NewEventHandlerUPP(keyPressed);
	InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 1, &eventType, NULL, NULL);
}
#endif

/* doSafeInitialisation
 * Do the stuff that requires that all NIBs are awoken. I can't find a notification
 * from Cocoa for this so we hack it.
 */
-(void)doSafeInitialisation
{
	static BOOL doneSafeInit = NO;
	if (!doneSafeInit)
	{
		[foldersTree initialiseFoldersTree];
		[mainArticleView initialiseArticleView];

		// Select the folder and article from the last session
		Preferences * prefs = [Preferences standardPreferences];
		int previousFolderId = [prefs integerForKey:MAPref_CachedFolderID];
		NSString * previousArticleGuid = [prefs stringForKey:MAPref_CachedArticleGUID];
		if ([previousArticleGuid isBlank])
			previousArticleGuid = nil;
		[[articleController mainArticleView] selectFolderAndArticle:previousFolderId guid:previousArticleGuid];

		// Make article list the first responder
		[mainWindow makeFirstResponder:primaryView];		

		doneSafeInit = YES;
	}
	didCompleteInitialisation = YES;
}

/* localiseMenus
 * As of 2.0.1, the menu localisation is now done through the Localizable.strings file rather than
 * the NIB file due to the effort in managing localised NIBs for an increasing number of languages.
 * Also, note care is taken not to localise those commands that were added by the OS. If there is
 * no equivalent in the Localizable.strings file, we do nothing.
 */
-(void)localiseMenus:(NSArray *)arrayOfMenus
{
	int count = [arrayOfMenus count];
	int index;
	
	for (index = 0; index < count; ++index)
	{
		NSMenuItem * menuItem = [arrayOfMenus objectAtIndex:index];
		if (menuItem != nil && ![menuItem isSeparatorItem])
		{
			NSString * localisedMenuTitle = NSLocalizedString([menuItem title], nil);
			if ([menuItem submenu])
			{
				NSMenu * subMenu = [menuItem submenu];
				if (localisedMenuTitle != nil)
					[subMenu setTitle:localisedMenuTitle];
				[self localiseMenus:[subMenu itemArray]];
			}
			if (localisedMenuTitle != nil)
				[menuItem setTitle:localisedMenuTitle];
		}
	}
}

#pragma mark Application Delegate

/* applicationWillFinishLaunching
 * Handle pre-load activities.
 */
-(void)applicationWillFinishLaunching:(NSNotification *)aNot
{
#ifdef GNUSTEP
	[self buildMainMenu];
	[self awakeFromNib];
#endif

	//Ensure the spinner has the proper state; it may be added while we're refreshing
	if ([NSApp isRefreshing])
	{
		[spinner setHidden: NO];
		// [spinner startAnimation:self];
	}
	else
	{
		[spinner setHidden: YES];
	}
}

/* applicationDidFinishLaunching
 * Handle post-load activities.
 */
-(void)applicationDidFinishLaunching:(NSNotification *)aNot
{
	Preferences * prefs = [Preferences standardPreferences];

	// Hook up the key sequence properly now that all NIBs are loaded.
	[[foldersTree mainView] setNextKeyView: primaryView];
	
	// Kick off an initial refresh
	if ([prefs refreshOnStartup])
		[self refreshAllSubscriptions:self];

	[self showMainWindow: self];
}

/* applicationShouldHandleReopen
 * Handle the notification sent when the application is reopened such as when the dock icon
 * is clicked. If the main window was previously hidden, we show it again here.
 */
-(BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	[self showMainWindow:self];
	if (emptyTrashWarning != nil)
		[emptyTrashWarning showWindow:self];
	return YES;
}

/* applicationShouldTerminate
 * This function is called when the user wants to close Vienna. First we check to see
 * if a connection or import is running and that all articles are saved.
 */
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	int returnCode;
	
	if ([[DownloadManager sharedInstance] activeDownloads] > 0)
	{
		returnCode = NSRunAlertPanel(NSLocalizedString(@"Downloads Running", nil),
									 NSLocalizedString(@"Downloads Running text", nil),
									 NSLocalizedString(@"Quit", nil),
									 NSLocalizedString(@"Cancel", nil),
									 nil);
		if (returnCode == NSAlertAlternateReturn)
			return NSTerminateCancel;
	}
	
	switch ([[Preferences standardPreferences] integerForKey:MAPref_EmptyTrashNotification])
	{
		case MA_EmptyTrash_None: break;
		
		case MA_EmptyTrash_WithoutWarning:
			if (![db isTrashEmpty])
			{
				[db purgeDeletedArticles];
			}
			break;
		
		case MA_EmptyTrash_WithWarning:
			if (![db isTrashEmpty])
			{
				if (emptyTrashWarning == nil)
					emptyTrashWarning = [[EmptyTrashWarning alloc] init];
				if ([emptyTrashWarning shouldEmptyTrash])
				{
					[db purgeDeletedArticles];
				}
				[emptyTrashWarning release];
				emptyTrashWarning = nil;
			}
			break;
		
		default: break;
	}
	
	return NSTerminateNow;
}

/* applicationWillTerminate
 * This is where we put the clean-up code.
 */
-(void)applicationWillTerminate:(NSNotification *)aNotification
{
	if (didCompleteInitialisation)
	{
		// Save the splitview layout
		Preferences * prefs = [Preferences standardPreferences];
		[prefs setObject:[splitView1 layout] forKey:@"SplitView1Positions"];

		// Close the activity window explicitly to force it to
		// save its split bar position to the preferences.
		NSWindow * activityWindow = [activityViewer window];
		[activityWindow performClose:self];
		
		// Put back the original app icon
		[NSApp setApplicationIconImage:originalIcon];

		// Remember the article list column position, sizes, etc.
		[mainArticleView saveTableSettings];
		[foldersTree saveFolderSettings];
		
		// Finally save preferences
		[prefs savePreferences];
	}
	[db close];
}

/* openFile [delegate]
 * Called when the user opens a data file associated with Vienna by clicking in the finder or dragging it onto the dock.
 */
-(BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	Preferences * prefs = [Preferences standardPreferences];
	if ([[filename pathExtension] isEqualToString:@"viennastyle"])
	{
		NSString * path = [prefs stylesFolder];
		NSString * styleName = [[filename lastPathComponent] stringByDeletingPathExtension];
		NSString * fullPath = [path stringByAppendingPathComponent:[filename lastPathComponent]];
		
		// Make sure we actually have a Styles folder.
		NSFileManager * fileManager = [NSFileManager defaultManager];
		BOOL isDir = NO;
		
		if (![fileManager fileExistsAtPath:path isDirectory:&isDir])
		{
			if (![fileManager createDirectoryAtPath:path attributes:NULL])
			{
				runOKAlertPanel(@"Cannot create style folder title", @"Cannot create style folder body", path);
				return NO;
			}
		}
		[fileManager removeFileAtPath:fullPath handler:nil];
		if (![fileManager copyPath:filename toPath:fullPath handler:nil])
			[[Preferences standardPreferences] setDisplayStyle:styleName];
		else
		{
			Preferences * prefs = [Preferences standardPreferences];
			[self initStylesMenu];
			[prefs setDisplayStyle:styleName];
			if ([[prefs displayStyle] isEqualToString:styleName])
				runOKAlertPanel(@"New style title", @"New style body", styleName);
		}
		return YES;
	}
	if ([[filename pathExtension] isEqualToString:@"opml"])
	{
		BOOL returnCode = NSRunAlertPanel(NSLocalizedString(@"Import subscriptions from OPML file?", nil), NSLocalizedString(@"Do you really want to import the subscriptions from the specified OPML file?", nil), NSLocalizedString(@"Import", nil), NSLocalizedString(@"Cancel", nil), nil);
		if (returnCode == NSAlertAlternateReturn)
			return NO;
		[self importFromFile:filename];
	}
	return NO;
}

/* searchFieldMenu
 * Change action for search action.
 */
-(void)searchMenuAction:(id)sender
{
	searchMenuTag = [sender tag];
}

/* searchFieldMenu
 * Allocates a popup menu for one of the search fields we use.
 */
-(NSMenu *)searchFieldMenu
{
	NSMenu * cellMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
	
	NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"All", nil) action:@selector(searchMenuAction:) keyEquivalent:@""];
	[item setTag: MA_Search_All];
	[cellMenu insertItem:item atIndex:0];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Selected Folder", nil) action:@selector(searchMenuAction:) keyEquivalent:@""];
	[item setTag: MA_Search_Selected_Folder];
	[cellMenu insertItem:item atIndex:1];
	[item release];
	
	return [cellMenu autorelease];
}

/* standardURLs
 */
-(NSDictionary *)standardURLs
{
	return standardURLs;
}

/* primaryView
 */
-(NSView *)primaryView
{
	return primaryView;
}

/* constrainMinCoordinate
 * Make sure the folder width isn't shrunk beyond a minimum width. Otherwise it looks
 * untidy.
 */
-(float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	return (sender == splitView1 && offset == 0) ? MA_Minimum_Folder_Pane_Width : proposedMin;
}

/* constrainMaxCoordinate
 * Make sure that the browserview isn't shrunk beyond a minimum size otherwise the splitview
 * or controls within it start resizing odd.
 */
-(float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	if (sender == splitView1 && offset == 0)
	{
		NSRect mainFrame = [[splitView1 superview] frame];
		return mainFrame.size.width - MA_Minimum_BrowserView_Pane_Width;
	}
	return proposedMax;
}

/* resizeSubviewsWithOldSize
 * Constrain the folder pane to a fixed width.
 */
-(void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	float dividerThickness = [sender dividerThickness];
	id sv1 = [[sender subviews] objectAtIndex:0];
	id sv2 = [[sender subviews] objectAtIndex:1];
	NSRect leftFrame = [sv1 frame];
	NSRect rightFrame = [sv2 frame];
	NSRect newFrame = [sender frame];
	
	if (sender == splitView1)
	{
		leftFrame.size.height = newFrame.size.height;
		leftFrame.origin = NSMakePoint(0, 0);
		rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
		rightFrame.size.height = newFrame.size.height;
		rightFrame.origin.x = leftFrame.size.width + dividerThickness;
		
		[sv1 setFrame:leftFrame];
		[sv2 setFrame:rightFrame];
	}
}

/* folderMenu
 * Dynamically create the popup menu. This is one less thing to
 * explicitly localise in the NIB file.
 */
-(NSMenu *)folderMenu
{
	NSMenu * folderMenu = [[[NSMenu alloc] init] autorelease];
	[folderMenu addItem:copyOfMenuWithAction(@selector(refreshSelectedSubscriptions:))];
	[folderMenu addItem:[NSMenuItem separatorItem]];
	[folderMenu addItem:copyOfMenuWithAction(@selector(editFolder:))];
	[folderMenu addItem:copyOfMenuWithAction(@selector(deleteFolder:))];
	[folderMenu addItem:copyOfMenuWithAction(@selector(renameFolder:))];
	[folderMenu addItem:[NSMenuItem separatorItem]];
	[folderMenu addItem:copyOfMenuWithAction(@selector(markAllRead:))];
	[folderMenu addItem:[NSMenuItem separatorItem]];
	[folderMenu addItem:copyOfMenuWithAction(@selector(viewSourceHomePage:))];
	[folderMenu addItem:copyOfMenuWithAction(@selector(getInfo:))];
	return folderMenu;
}

/* reportLayout
 * Switch to report layout
 */
-(IBAction)reportLayout:(id)sender
{
	[self setLayout:MA_Layout_Report withRefresh:YES];
}

/* condensedLayout
 * Switch to condensed layout
 */
-(IBAction)condensedLayout:(id)sender
{
	[self setLayout:MA_Layout_Condensed withRefresh:YES];
}

/* unifiedLayout
 * Switch to unified layout.
 */
-(IBAction)unifiedLayout:(id)sender
{
	[self setLayout:MA_Layout_Unified withRefresh:YES];
}

/* setLayout
 * Changes the layout of the panes.
 */
-(void)setLayout:(int)newLayout withRefresh:(BOOL)refreshFlag
{
	int oldLayout = [[Preferences standardPreferences] layout];
	if ((oldLayout == newLayout) && (primaryView != nil))
		return;

	NSRect frame = [articleFrame frame];
	frame.origin = NSMakePoint(0, 0);
	frame.size.width -= 10;

	[primaryView removeFromSuperview];

	switch (newLayout)
	{
	case MA_Layout_Report:
		if (mainArticleView == nil)
			[self buildMainArticleView];
		primaryView = mainArticleView;
		[primaryView setFrame: frame];
		[articleFrame addSubview: primaryView];
		if (refreshFlag)
			[mainArticleView refreshFolder:MA_Refresh_RedrawList];
		[articleController setMainArticleView:mainArticleView];
		break;

	case MA_Layout_Condensed:
		if (mainArticleView == nil)
			[self buildMainArticleView];
		primaryView = mainArticleView;
		[primaryView setFrame: frame];
		[articleFrame addSubview: primaryView];
		if (refreshFlag)
			[mainArticleView refreshFolder:MA_Refresh_RedrawList];
		[articleController setMainArticleView:mainArticleView];
		break;

	case MA_Layout_Unified:
		if (unifiedListView == nil)
			[self buildUnifiedDisplayView];
		primaryView = unifiedListView;
		[primaryView setFrame: frame];
		[articleFrame addSubview: primaryView];
		if (refreshFlag)
			[unifiedListView refreshFolder:MA_Refresh_RedrawList];
		[articleController setMainArticleView:unifiedListView];
		break;
	}

	[[Preferences standardPreferences] setLayout:newLayout];
	[self updateSearchPlaceholder];
	[[foldersTree mainView] setNextKeyView:primaryView];
}

#pragma mark Dock Menu

/* contextMenuItemsForElement
 * Creates a new context menu for our web pane.
 */
-(NSArray *)contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
#if 1
	return nil;
#else
	NSMutableArray * newDefaultMenu = [[NSMutableArray alloc] initWithArray:defaultMenuItems];
	NSURL * urlLink = [element valueForKey:WebElementLinkURLKey];
	NSURL * imageURL;
	NSString * defaultBrowser = getDefaultBrowser();
	if (defaultBrowser == nil)
		defaultBrowser = NSLocalizedString(@"External Browser", nil);
	NSMenuItem * newMenuItem;
	int count = [newDefaultMenu count];
	int index;
	
	// Note: this is only safe to do if we're going from [count..0] when iterating
	// over newDefaultMenu. If we switch to the other direction, this will break.
	for (index = count - 1; index >= 0; --index)
	{
		NSMenuItem * menuItem = [newDefaultMenu objectAtIndex:index];
		switch ([menuItem tag])
		{
			case WebMenuItemTagOpenImageInNewWindow:
				imageURL = [element valueForKey:WebElementImageURLKey];
				if (imageURL != nil)
				{
					[menuItem setTitle:NSLocalizedString(@"Open Image in New Tab", nil)];
					[menuItem setTarget:self];
					[menuItem setAction:@selector(openWebElementInNewTab:)];
					[menuItem setRepresentedObject:imageURL];
					[menuItem setTag:WebMenuItemTagOther];
					newMenuItem = [[NSMenuItem alloc] init];
					if (newMenuItem != nil)
					{
						[newMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Open Image in %@", nil), defaultBrowser]];
						[newMenuItem setTarget:self];
						[newMenuItem setAction:@selector(openWebElementInDefaultBrowser:)];
						[newMenuItem setRepresentedObject:imageURL];
						[newMenuItem setTag:WebMenuItemTagOther];
						[newDefaultMenu insertObject:newMenuItem atIndex:index + 1];
					}
					[newMenuItem release];
				}
					break;
				
			case WebMenuItemTagOpenFrameInNewWindow:
				[menuItem setTitle:NSLocalizedString(@"Open Frame", nil)];
				break;
				
			case WebMenuItemTagOpenLinkInNewWindow:
				[menuItem setTitle:NSLocalizedString(@"Open Link in New Tab", nil)];
				[menuItem setTarget:self];
				[menuItem setAction:@selector(openWebElementInNewTab:)];
				[menuItem setRepresentedObject:urlLink];
				[menuItem setTag:WebMenuItemTagOther];
				newMenuItem = [[NSMenuItem alloc] init];
				if (newMenuItem != nil)
				{
					[newMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Open Link in %@", nil), defaultBrowser]];
					[newMenuItem setTarget:self];
					[newMenuItem setAction:@selector(openWebElementInDefaultBrowser:)];
					[newMenuItem setRepresentedObject:urlLink];
					[newMenuItem setTag:WebMenuItemTagOther];
					[newDefaultMenu insertObject:newMenuItem atIndex:index + 1];
				}
					[newMenuItem release];
				break;
				
			case WebMenuItemTagCopyLinkToClipboard:
				[menuItem setTitle:NSLocalizedString(@"Copy Link to Clipboard", nil)];
				break;
		}
	}
	
	if (urlLink == nil)
	{
		// Separate our new commands from the existing ones.
		[newDefaultMenu addObject:[NSMenuItem separatorItem]];
		
		// Add command to open the current page in the external browser
		newMenuItem = [[NSMenuItem alloc] init];
		if (newMenuItem != nil)
		{
			[newMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Open Page in %@", nil), defaultBrowser]];
			[newMenuItem setTarget:self];
			[newMenuItem setAction:@selector(openPageInBrowser:)];
			[newMenuItem setTag:WebMenuItemTagOther];
			[newDefaultMenu addObject:newMenuItem];
		}
		[newMenuItem release];
		
		// Add command to copy the URL of the current page to the clipboard
		newMenuItem = [[NSMenuItem alloc] init];
		if (newMenuItem != nil)
		{
			[newMenuItem setTitle:NSLocalizedString(@"Copy Page Link to Clipboard", nil)];
			[newMenuItem setTarget:self];
			[newMenuItem setAction:@selector(copyPageURLToClipboard:)];
			[newMenuItem setTag:WebMenuItemTagOther];
			[newDefaultMenu addObject:newMenuItem];
		}
		[newMenuItem release];
	}
	
	return [newDefaultMenu autorelease];
#endif
}

/* openWebElementInDefaultBrowser
 * Open the specified element in an external browser
 */
-(IBAction)openWebElementInDefaultBrowser:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]])
	{
		NSMenuItem * item = (NSMenuItem *)sender;
		[self openURLInDefaultBrowser:[item representedObject]];
	}
}

/* openURLFromString
 * Open a URL in either the internal Vienna browser or an external browser depending on
 * whatever the user has opted for.
 */
-(void)openURLFromString:(NSString *)urlString inPreferredBrowser:(BOOL)openInPreferredBrowserFlag
{
	[self openURL:[NSURL URLWithString:urlString] inPreferredBrowser:openInPreferredBrowserFlag];
}

/* openURL
 * Open a URL in either the internal Vienna browser or an external browser depending on
 * whatever the user has opted for.
 */
-(void)openURL:(NSURL *)url inPreferredBrowser:(BOOL)openInPreferredBrowserFlag
{
	if (url == nil)
	{
		NSLog(@"Called openURL:inPreferredBrowser: with nil url.");
		return;
	}
	
	[self openURLInDefaultBrowser:url];
}

/* downloadEnclosure
 * Downloads the enclosures of the currently selected articles
 */
-(IBAction)downloadEnclosure:(id)sender
{
	Article * selectedMessage = [self selectedArticle];
	if ([selectedMessage hasEnclosure])
	{
		NSString * filename = [[selectedMessage enclosure] lastPathComponent];
		NSString * destPath = [DownloadManager fullDownloadPath:filename];

		[[DownloadManager sharedInstance] downloadFile:destPath fromURL:[selectedMessage enclosure]];
	}
}

/* openURLInDefaultBrowser
 * Open the specified URL in whatever the user has registered as their
 * default system browser.
 */
-(void)openURLInDefaultBrowser:(NSURL *)url
{
	Preferences * prefs = [Preferences standardPreferences];
	
	// This line is a workaround for OS X bug rdar://4450641
	if ([prefs openLinksInBackground])
		[mainWindow orderFront:self];
	// Launch in the foreground or background as needed
#ifdef GNUSTEP	
	[[NSWorkspace sharedWorkspace] openURL:url];
#else
	NSWorkspaceLaunchOptions lOptions = [prefs openLinksInBackground] ? NSWorkspaceLaunchWithoutActivation : NSWorkspaceLaunchDefault;
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url]
					withAppBundleIdentifier:NULL
									options:lOptions
			 additionalEventParamDescriptor:NULL
						  launchIdentifiers:NULL];
#endif
}

/* setImageForMenuCommand
 * Sets the image for a specified menu command.
 */
-(void)setImageForMenuCommand:(NSImage *)image forAction:(SEL)sel
{
	NSArray * arrayOfMenus = [[NSApp mainMenu] itemArray];
	int count = [arrayOfMenus count];
	int index;
	
	for (index = 0; index < count; ++index)
	{
		NSMenu * subMenu = [[arrayOfMenus objectAtIndex:index] submenu];
		int itemIndex = [subMenu indexOfItemWithTarget:self andAction:sel];
		if (itemIndex >= 0)
		{
			[[subMenu itemAtIndex:itemIndex] setImage:image];
			return;
		}
	}
}

/* openVienna
 * Calls into showMainWindow but activates the app first.
 */
-(IBAction)openVienna:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[self showMainWindow:sender];
}

/* showMainWindow
 * Display the main window.
 */
-(IBAction)showMainWindow:(id)sender
{
	[mainWindow makeKeyAndOrderFront:self];
}

/* initSortMenu
 * Create the sort popup menu.
 */
-(void)initSortMenu
{
	NSMenu * sortMenu = [[[NSMenu alloc] initWithTitle:@"Sort By"] autorelease];
	NSArray * fields = [db arrayOfFields];
	NSEnumerator * enumerator = [fields objectEnumerator];
	Field * field;
	
	while ((field = [enumerator nextObject]) != nil)
	{
		// Filter out columns we don't sort on. Later we should have an attribute in the
		// field object itself based on which columns we can sort on.
		if ([field tag] != MA_FieldID_Parent &&
			[field tag] != MA_FieldID_GUID &&
			[field tag] != MA_FieldID_Comments &&
			[field tag] != MA_FieldID_Deleted &&
			[field tag] != MA_FieldID_Headlines &&
			[field tag] != MA_FieldID_Summary &&
			[field tag] != MA_FieldID_Link &&
			[field tag] != MA_FieldID_Text &&
			[field tag] != MA_FieldID_EnclosureDownloaded &&
			[field tag] != MA_FieldID_Enclosure)
		{
			NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:[field displayName] action:@selector(doSortColumn:) keyEquivalent:@""];
			[menuItem setRepresentedObject:field];
			[sortMenu addItem:menuItem];
			[menuItem release];
		}
	}
	[sortByMenu setSubmenu:sortMenu];
}

/* initColumnsMenu
 * Create the columns popup menu.
 */
-(void)initColumnsMenu
{
	NSMenu * columnsSubMenu = [[[NSMenu alloc] initWithTitle:@"Columns"] autorelease];
	NSArray * fields = [db arrayOfFields];
	NSEnumerator * enumerator = [fields objectEnumerator];
	Field * field;
	
	while ((field = [enumerator nextObject]) != nil)
	{
		// Filter out columns we don't view in the article list. Later we should have an attribute in the
		// field object based on which columns are visible in the tableview.
		if ([field tag] != MA_FieldID_Text && 
			[field tag] != MA_FieldID_GUID &&
			[field tag] != MA_FieldID_Comments &&
			[field tag] != MA_FieldID_Deleted &&
			[field tag] != MA_FieldID_Parent &&
			[field tag] != MA_FieldID_Headlines &&
			[field tag] != MA_FieldID_EnclosureDownloaded)
		{
			NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:[field displayName] action:@selector(doViewColumn:) keyEquivalent:@""];
			[menuItem setRepresentedObject:field];
			[columnsSubMenu addItem:menuItem];
			[menuItem release];
		}
	}
	[columnsMenu setSubmenu:columnsSubMenu];
}

/* initStylesMenu
 * Populate the Styles menu with a list of built-in and external styles. (Note that in the event of
 * duplicates the styles in the external Styles folder wins. This is intended to allow the user to
 * override the built-in styles if necessary).
 */
-(void)initStylesMenu
{
	NSMenu * stylesSubMenu = [[[NSMenu alloc] initWithTitle:@"Style"] autorelease];
	
	// Reinitialise the styles map
	NSDictionary * stylesMap = [ArticleView loadStylesMap];
	
	// Add the contents of the stylesPathMappings dictionary keys to the menu sorted by key name.
	NSArray * sortedMenuItems = [[stylesMap allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	int count = [sortedMenuItems count];
	int index;
	
	for (index = 0; index < count; ++index)
	{
		NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:[sortedMenuItems objectAtIndex:index] action:@selector(doSelectStyle:) keyEquivalent:@""];
		[stylesSubMenu addItem:menuItem];
		[menuItem release];
	}
	
	// Add it to the Style menu
	[stylesMenu setSubmenu:stylesSubMenu];
}

/* updateNewArticlesNotification
 * Respond to a change in how we notify when new articles are retrieved.
 */
-(void)updateNewArticlesNotification
{
	lastCountOfUnread = -1;	// Force an update
	[self showUnreadCountOnApplicationIconAndWindowTitle];
}

/* showUnreadCountOnApplicationIconAndWindowTitle
 * Update the Vienna application icon to show the number of unread articles.
 */
-(void)showUnreadCountOnApplicationIconAndWindowTitle
{
	int currentCountOfUnread = [db countOfUnread];
	if (currentCountOfUnread == lastCountOfUnread)
		return;
	lastCountOfUnread = currentCountOfUnread;

	// Don't show a count if there are no unread articles
	if (currentCountOfUnread <= 0)
	{
		[NSApp setApplicationIconImage:originalIcon];
		[mainWindow setTitle:[self appName]];
		return;	
	}	

	[mainWindow setTitle:[[NSString stringWithFormat:@"%@ -", [self appName]]
		stringByAppendingString:[NSString stringWithFormat:
			NSLocalizedString(@" (%d unread)", nil), currentCountOfUnread]]];

	NSString * countdown = [NSString stringWithFormat:@"%i", currentCountOfUnread];
	NSImage * iconImageBuffer = [originalIcon copy];
	NSSize iconSize = [originalIcon size];
	
	// Create attributes for drawing the count. In our case, we're drawing using in
	// 26pt Helvetica bold white.
	NSDictionary * attributes = [[NSDictionary alloc] 
		initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:25], NSFontAttributeName,
		[NSColor whiteColor], NSForegroundColorAttributeName, nil];
	NSSize numSize = [countdown sizeWithAttributes:attributes];
	
	// Create a red circle in the icon large enough to hold the count.
	[iconImageBuffer lockFocus];
	[originalIcon drawAtPoint:NSMakePoint(0, 0)
					 fromRect:NSMakeRect(0, 0, iconSize.width, iconSize.height) 
					operation:NSCompositeSourceOver 
					 fraction:1.0f];
	
	float max = (numSize.width > numSize.height) ? numSize.width : numSize.height;
	max += 21;
	NSRect circleRect = NSMakeRect(iconSize.width - max, iconSize.height - max, max, max);
	
	// Draw the star image and scale it so the unread count will fit inside.
	NSImage * starImage = [NSImage imageNamed:@"unreadStar1.tiff"];
	[starImage setScalesWhenResized:YES];
	[starImage setSize:circleRect.size];
	[starImage compositeToPoint:circleRect.origin operation:NSCompositeSourceOver];
	
	// Draw the count in the red circle
	NSPoint point = NSMakePoint(NSMidX(circleRect) - numSize.width / 2.0f + 2.0f,  NSMidY(circleRect) - numSize.height / 2.0f + 2.0f);
	[countdown drawAtPoint:point withAttributes:attributes];
	
	// Now set the new app icon and clean up.
	[iconImageBuffer unlockFocus];
	[NSApp setApplicationIconImage:iconImageBuffer];
	[iconImageBuffer release];
	[attributes release];
}

/* emptyTrash
 * Delete all articles from the Trash folder.
 */
-(IBAction)emptyTrash:(id)sender
{
	NSBeginCriticalAlertSheet(NSLocalizedString(@"Empty Trash message", nil),
							  NSLocalizedString(@"Empty", nil),
							  NSLocalizedString(@"Cancel", nil),
							  nil, [NSApp mainWindow], self,
							  @selector(doConfirmedEmptyTrash:returnCode:contextInfo:), NULL, nil,
							  NSLocalizedString(@"Empty Trash message text", nil));
}

/* doConfirmedEmptyTrash
 * This function is called after the user has dismissed
 * the confirmation sheet.
 */
-(void)doConfirmedEmptyTrash:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn)
	{
		[self clearUndoStack];
		[db purgeDeletedArticles];
	}
}

/* showPreferencePanel
 * Display the Preference Panel.
 */
-(IBAction)showPreferencePanel:(id)sender
{
	if (!preferenceController)
		preferenceController = [[NewPreferencesController alloc] init];
	[NSApp activateIgnoringOtherApps:YES];
	[preferenceController showWindow:self];
}

/* printDocument
 * Print the selected articles in the article window.
 */
-(IBAction)printDocument:(id)sender
{
	[primaryView printDocument:sender];
}

/* folders
 * Return the array of folders.
 */
-(NSArray *)folders
{
	return [db arrayOfAllFolders];
}

/* appName
 * Returns's the application friendly (localized) name.
 */
-(NSString *)appName
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

/* selectedArticle
 * Returns the current selected article in the article pane.
 */
-(Article *)selectedArticle
{
	return [articleController selectedArticle];
}

/* currentFolderId
 * Return the ID of the currently selected folder whose articles are shown in
 * the article window.
 */
-(int)currentFolderId
{
	return [articleController currentFolderId];
}

/* selectFolder
 * Select the specified folder.
 */
-(void)selectFolder:(int)folderId
{
	[foldersTree selectFolder:folderId];
}

/* handleEditFolder
 * Respond to an edit folder notification.
 */
-(void)handleEditFolder:(NSNotification *)nc
{
	TreeNode * node = (TreeNode *)[nc object];
	Folder * folder = [db folderFromID:[node nodeId]];
	[self doEditFolder:folder];
}

/* editFolder
 * Handles the Edit command
 */
-(IBAction)editFolder:(id)sender
{
	Folder * folder = [db folderFromID:[foldersTree actualSelection]];
	[self doEditFolder:folder];
}

/* doEditFolder
 * Handles an edit action on the specified folder.
 */
-(void)doEditFolder:(Folder *)folder
{
	if (IsRSSFolder(folder))
	{
		if (!rssFeed)
			rssFeed = [[NewSubscription alloc] initWithDatabase:db];
		[rssFeed editSubscription:mainWindow folderId:[folder itemId]];
	}
	else if (IsSmartFolder(folder))
	{
		if (!smartFolder)
			smartFolder = [[SmartFolder alloc] initWithDatabase:db];
		[smartFolder loadCriteria:mainWindow folderId:[folder itemId]];
	}
}

/* handleFolderSelection
 * Called when the selection changes in the folder pane.
 */
-(void)handleFolderSelection:(NSNotification *)nc
{
	TreeNode * node = (TreeNode *)[nc object];
	int newFolderId = [node nodeId];

	// We don't filter when we switch folders.
	[self setSearchString:@""];

	// Call through the controller to display the new folder.
	[articleController displayFolder:newFolderId];
	[self updateSearchPlaceholder];
}

/* handleDidBecomeKeyWindow
 * Called when a window becomes the key window.
 */
-(void)handleDidBecomeKeyWindow:(NSNotification *)nc
{
}

/* handleReloadPreferences
 * Called when MA_Notify_PreferencesUpdated is broadcast.
 */
-(void)handleReloadPreferences:(NSNotification *)nc
{
	[self updateNewArticlesNotification];
}

/* handleCheckFrequencyChange
 * Called when the refresh frequency is changed.
 */
-(void)handleCheckFrequencyChange:(NSNotification *)nc
{
NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	int newFrequency = [[Preferences standardPreferences] refreshFrequency];
	
	if (checkTimer)
	{
		if ([checkTimer isValid])
		{
			[checkTimer invalidate];
		}
		[checkTimer release];
		checkTimer = nil;
	}
	if (newFrequency > 0)
	{
		checkTimer = [[NSTimer scheduledTimerWithTimeInterval:newFrequency
													   target:self
													 selector:@selector(refreshOnTimer:)
													 userInfo:nil
													  repeats:NO] retain];
	}
NSLog(@"%@ %@ done", self, NSStringFromSelector(_cmd));
}

/* checkTimer
 * Return the refresh timer object.
 */
-(NSTimer *)checkTimer
{
	return checkTimer;
}

/* doViewColumn
 * Toggle whether or not a specified column is visible.
 */
-(IBAction)doViewColumn:(id)sender;
{
	NSMenuItem * menuItem = (NSMenuItem *)sender;
	Field * field = [menuItem representedObject];
	
	[field setVisible:![field visible]];
	if ([[field name] isEqualToString:MA_Field_Summary] && [field visible])
		[articleController createArticleSummaries];
	[mainArticleView updateVisibleColumns];
	[mainArticleView saveTableSettings];
}

/* doSortColumn
 * Handle the user picking an item from the Sort By submenu
 */
-(IBAction)doSortColumn:(id)sender
{
	NSMenuItem * menuItem = (NSMenuItem *)sender;
	Field * field = [menuItem representedObject];
	
	NSAssert1(field, @"Somehow got a nil representedObject for Sort sub-menu item '%@'", [menuItem title]);
	[articleController sortByIdentifier:[field name]];
}

/* doSelectStyle
 * Handle a selection from the Style menu.
 */
-(IBAction)doSelectStyle:(id)sender
{
	NSMenuItem * menuItem = (NSMenuItem *)sender;
	[[Preferences standardPreferences] setDisplayStyle:[menuItem title]];
}

/* handleFolderNameChange
 * Handle folder name change.
 */
-(void)handleFolderNameChange:(NSNotification *)nc
{
	int folderId = [(NSNumber *)[nc object] intValue];
	if (folderId == [articleController currentFolderId])
		[self updateSearchPlaceholder];
}

/* handleRefreshStatusChange
 * Handle a change of the refresh status.
 */
-(void)handleRefreshStatusChange:(NSNotification *)nc
{
	if ([NSApp isRefreshing])
	{
		// Save the date/time of this refresh so we do the right thing when
		// we apply the filter.
		[[Preferences standardPreferences] setObject:[NSCalendarDate date] forKey:MAPref_LastRefreshDate];
		
		[self startProgressIndicator];
		[self setStatusMessage:[[RefreshManager sharedManager] statusMessageDuringRefresh] persist:YES];
	}
	else
	{
		// Run the auto-expire now
		Preferences * prefs = [Preferences standardPreferences];
		[db purgeArticlesOlderThanDays:[prefs autoExpireDuration]];
		
		[self setStatusMessage:NSLocalizedString(@"Refresh completed", nil) persist:YES];
		[self stopProgressIndicator];
		
		[self showUnreadCountOnApplicationIconAndWindowTitle];
		
		// Refresh the current folder.
		[articleController refreshCurrentFolder];
	}
}

/* viewArticlePage
 * Display the article in the browser.
 */
-(IBAction)viewArticlePage:(id)sender
{
	Article * theArticle = [self selectedArticle];
	if (theArticle && ![[theArticle link] isBlank])
		[self openURLFromString:[theArticle link] inPreferredBrowser:YES];
}

/* goForward
 * In article view, forward track through the list of articles displayed. In 
* web view, go to the next web page.
 */
-(IBAction)goForward:(id)sender
{
	[primaryView handleGoForward:sender];
}

/* goBack
 * In article view, back track through the list of articles displayed. In 
 * web view, go to the previous web page.
 */
-(IBAction)goBack:(id)sender
{
	[primaryView handleGoBack:sender];
}

/* localPerformFindPanelAction
 * The default handler for the Find actions is the first responder. Unfortunately the
 * WebView, although it claims to implement this, doesn't. So we redirect the Find
 * commands here and trap the case where the webview has first responder status and
 * handle it especially. For other first responders, we pass this command through.
 */
-(IBAction)localPerformFindPanelAction:(id)sender
{
#ifndef GNUSTEP
	switch ([sender tag]) 
	{
	case NSFindPanelActionSetFindString:
		[searchField setStringValue:[NSApp currentSelection]];
		[mainWindow makeFirstResponder:searchField];
		break;

	case NSFindPanelActionShowFindPanel:
		[mainWindow makeFirstResponder:searchField];
		break;
		
	default:
		[primaryView performFindPanelAction:[sender tag]];
		break;
	}
#endif
}

#pragma mark Key Listener

/* handleKeyDown [delegate]
 * Support special key codes. If we handle the key, return YES otherwise
 * return NO to allow the framework to pass it on for default processing.
 */
-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(unsigned int)flags
{
	if (keyChar >= '0' && keyChar <= '9' && (flags & NSControlKeyMask))
	{
		int layoutStyle = MA_Layout_Report + (keyChar - '0');
		[self setLayout:layoutStyle withRefresh:YES];
		return YES;
	}
	switch (keyChar)
	{
		case NSLeftArrowFunctionKey:
			if (flags & NSCommandKeyMask)
				return NO;
			else
			{
				if ([mainWindow firstResponder] == primaryView)
				{
					[mainWindow makeFirstResponder:[foldersTree mainView]];
					return YES;
				}
			}
			return NO;
			
		case NSRightArrowFunctionKey:
			if (flags & NSCommandKeyMask)
				return NO;
			else
			{
				if ([mainWindow firstResponder] == [foldersTree mainView])
				{
					if ([self selectedArticle] == nil)
						[articleController ensureSelectedArticle:NO];
					[mainWindow makeFirstResponder:([self selectedArticle] != nil) ? primaryView : [foldersTree mainView]];
					return YES;
				}
			}
			return NO;
			
		case NSDeleteFunctionKey:
		case NSDeleteCharacter:
			if ([mainWindow firstResponder] == [foldersTree mainView])
			{
				[self deleteFolder:self];
				return YES;
			}
			else if ([mainWindow firstResponder] == [mainArticleView mainView])
			{
				[self deleteMessage:self];
				return YES;
			}
			return NO;

		case 'h':
		case 'H':
			[self setFocusToSearchField:self];
			return YES;
			
		case 'f':
		case 'F':
#if 0 // FIXME: should focus to search field
			if (![self isFilterBarVisible])
				[self setPersistedFilterBarState:YES withAnimation:YES];
			else
				[mainWindow makeFirstResponder:filterSearchField];
#endif
			return YES;
			
		case '>':
			[self goForward:self];
			return YES;
			
		case '<':
			[self goBack:self];
			return YES;
			
		case 'k':
		case 'K':
			[self markAllRead:self];
			return YES;
			
		case 'm':
		case 'M':
			[self markFlagged:self];
			return YES;
			
		case 'n':
		case 'N':
			[self viewNextUnread:self];
			return YES;
			
		case 'u':
		case 'U':
		case 'r':
		case 'R':
			[self markRead:self];
			return YES;
			
		case 's':
		case 'S':
			[self skipFolder:self];
			return YES;
			
		case NSEnterCharacter:
		case NSCarriageReturnCharacter:
			if ([mainWindow firstResponder] == [foldersTree mainView])
			{
				[self viewSourceHomePage:self];
				return YES;
			}
			else if ([mainWindow firstResponder] == [mainArticleView mainView])
			{
				[self viewArticlePage:self];
				return YES;
			}
			return NO;

		case ' ': //SPACE
		{
#if 1 // FIXME
			[self viewNextUnread:self];
#else
			WebView * view = [primaryView webView];
			NSView * theView = [[[view mainFrame] frameView] documentView];

			if (theView == nil)
				[self viewNextUnread:self];
			else
			{
				NSRect visibleRect = [theView visibleRect];
				if (flags & NSShiftKeyMask)
				{
					if (visibleRect.origin.y < 2)
						[self goBack:self];
					else
						[view scrollPageUp:self];
				}
				else
				{
					if (visibleRect.origin.y + visibleRect.size.height >= [theView frame].size.height - 2)
						[self viewNextUnread:self];
					else
						[view scrollPageDown:self];
				}
			}
#endif
			return YES;
		}
	}
	return NO;
}

/* toggleOptionKeyButtonStates
 * Toggles the appearance and function of the "Add" button while the option-key is pressed. 
 * Works and looks exactly as in the iApps. Currently only for toggling "Add Sub/Add Smart Folder", 
 * but of course it could be used for all other buttons as well.
 */
-(void)toggleOptionKeyButtonStates
{
	NSToolbarItem * item = [self toolbarItemWithIdentifier:@"Subscribe"];

	if (!([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)) 
	{
		[item setImage:[NSImage imageNamed:@"subscribeButton.tiff"]];
		[item setAction:@selector(newSubscription:)];
	}
	else
	{
		[item setImage:[NSImage imageNamed:@"smartFolderButton.tiff"]];
		[item setAction:@selector(newSmartFolder:)];
	}
}

/* toolbarItemWithIdentifier
 * Returns the toolbar button that corresponds to the specified identifier.
 */
-(NSToolbarItem *) toolbarItemWithIdentifier: (NSString *) theIdentifier
{
	NSArray * toolbarButtons = [[mainWindow toolbar] visibleItems];
	NSEnumerator * theEnumerator = [toolbarButtons objectEnumerator];
	NSToolbarItem * theItem;
	
	while ((theItem = [theEnumerator nextObject]) != nil)
	{
		if ([[theItem itemIdentifier] isEqualToString:theIdentifier])
			return theItem;
	}
	return nil;
}

/* isConnecting
 * Returns whether or not 
 */
-(BOOL)isConnecting
{
	return [[RefreshManager sharedManager] totalConnections] > 0;
}

/* refreshOnTimer
 * Each time the check timer fires, we see if a connect is not nswindow
 * running and then kick one off.
 */
-(void)refreshOnTimer:(NSTimer *)aTimer
{
NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[self refreshAllSubscriptions:self];
NSLog(@"%@ %@ done", self, NSStringFromSelector(_cmd));
}

/* markSelectedFoldersRead
 * Mark read all articles in the specified array of folders.
 */
-(void)markSelectedFoldersRead:(NSArray *)arrayOfFolders
{
	if (![db readOnly])
		[articleController markAllReadByArray:arrayOfFolders withUndo:YES withRefresh:YES];
}

/* createNewSubscription
 * Create a new subscription for the specified URL under the given 
 * parent folder.
 */
-(void)createNewSubscription:(NSString *)urlString underFolder:(int)parentId afterChild:(int)predecessorId
{
	// Replace feed:// with http:// if necessary
	if ([urlString hasPrefix:@"feed://"])
		urlString = [NSString stringWithFormat:@"http://%@", [urlString substringFromIndex:7]];
	
	// If the folder already exists, just select it.
	Folder * folder = [db folderFromFeedURL:urlString];
	if (folder != nil)
	{
		[foldersTree selectFolder:[folder itemId]];
		return;
	}
NSLog(@"New Feed %@", urlString);
	
	// Create then select the new folder.
	[db beginTransaction];
	int folderId = [db addRSSFolder:[Database untitledFeedFolderName] underParent:parentId afterChild:predecessorId subscriptionURL:urlString];
	[db commitTransaction];
	
	if (folderId != -1)
	{
		[foldersTree selectFolder:folderId];
		if (isAccessible(urlString))
		{
			Folder * folder = [db folderFromID:folderId];
			int total = [[RefreshManager sharedManager] refreshSubscriptions:[NSArray arrayWithObject:folder] ignoringSubscriptionStatus:NO];
			[spinner setMaxValue: total];
		}
	}
}

/* newSubscription
 * Display the pane for a new RSS subscription.
 */
-(IBAction)newSubscription:(id)sender
{
	if (!rssFeed)
		rssFeed = [[NewSubscription alloc] initWithDatabase:db];
	[rssFeed newSubscription:mainWindow underParent:[foldersTree groupParentSelection] initialURL:nil];
}

/* newSmartFolder
 * Create a new smart folder.
 */
-(IBAction)newSmartFolder:(id)sender
{
	if (!smartFolder)
		smartFolder = [[SmartFolder alloc] initWithDatabase:db];
	[smartFolder newCriteria:mainWindow underParent:[foldersTree groupParentSelection]];
}

/* newGroupFolder
 * Display the pane for a new group folder.
 */
-(IBAction)newGroupFolder:(id)sender
{
	if (!groupFolder)
		groupFolder = [[NewGroupFolder alloc] init];
	[groupFolder newGroupFolder:mainWindow underParent:[foldersTree groupParentSelection]];
}

/* restoreMessage
 * Restore a message in the Trash folder back to where it came from.
 */
-(IBAction)restoreMessage:(id)sender
{
	Folder * folder = [db folderFromID:[articleController currentFolderId]];
	if (IsTrashFolder(folder) && [self selectedArticle] != nil && ![db readOnly])
	{
		NSArray * articleArray = [mainArticleView markedArticleRange];
		[articleController markDeletedByArray:articleArray deleteFlag:NO];
		[self clearUndoStack];
	}
}

/* deleteMessage
 * Delete the current article. If we're in the Trash folder, this represents a permanent
 * delete. Otherwise we just move the article to the trash folder.
 */
-(IBAction)deleteMessage:(id)sender
{
	if ([self selectedArticle] != nil && ![db readOnly])
	{
		Folder * folder = [db folderFromID:[articleController currentFolderId]];
		if (!IsTrashFolder(folder))
		{
			NSArray * articleArray = [mainArticleView markedArticleRange];
			[articleController markDeletedByArray:articleArray deleteFlag:YES];
		}
		else
		{
			NSBeginCriticalAlertSheet(NSLocalizedString(@"Delete selected message", nil),
									  NSLocalizedString(@"Delete", nil),
									  NSLocalizedString(@"Cancel", nil),
									  nil, [NSApp mainWindow], self,
									  @selector(doConfirmedDelete:returnCode:contextInfo:), NULL, nil,
									  NSLocalizedString(@"Delete selected message text", nil));
		}
	}
}

/* doConfirmedDelete
 * This function is called after the user has dismissed
 * the confirmation sheet.
 */
-(void)doConfirmedDelete:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn)
	{
		NSArray * articleArray = [mainArticleView markedArticleRange];
		[articleController deleteArticlesByArray:articleArray];

		// Blow away the undo stack here since undo actions may refer to
		// articles that have been deleted. This is a bit of a cop-out but
		// it's the easiest approach for now.
		[self clearUndoStack];
	}
}

/* showDownloadsWindow
 * Show the Downloads window, bringing it to the front if necessary.
 */
-(IBAction)showDownloadsWindow:(id)sender
{
	if (downloadWindow == nil)
		downloadWindow = [[DownloadWindow alloc] init];
	[[downloadWindow window] makeKeyAndOrderFront:sender];
}

/* conditionalShowDownloadsWindow
 * Make the Downloads window visible only if it hasn't been shown.
 */
-(IBAction)conditionalShowDownloadsWindow:(id)sender
{
	if (downloadWindow == nil)
		downloadWindow = [[DownloadWindow alloc] init];
	if (![[downloadWindow window] isVisible])
		[[downloadWindow window] makeKeyAndOrderFront:sender];
}

/* toggleActivityViewer
 * Toggle display of the activity viewer windows.
 */
-(IBAction)toggleActivityViewer:(id)sender
{	
	if (activityViewer == nil)
		activityViewer = [[ActivityViewer alloc] init];
	if (activityViewer != nil)
	{
		NSWindow * activityWindow = [activityViewer window];
		if (![activityWindow isVisible])
			[activityViewer showWindow:self];
		else
			[activityWindow performClose:self];
	}
}

/* viewNextUnread
 * Moves the selection to the next unread article.
 */
-(IBAction)viewNextUnread:(id)sender
{
	if ([db countOfUnread] > 0)
		[articleController displayNextUnread];
	[mainWindow makeFirstResponder:([self selectedArticle] != nil) ? primaryView : [foldersTree mainView]];
}

/* clearUndoStack
 * Clear the undo stack for instances when the last action invalidates
 * all previous undoable actions.
 */
-(void)clearUndoStack
{
	[[mainWindow undoManager] removeAllActions];
}

/* skipFolder
 * Mark all articles in the current folder read then skip to the next folder with
 * unread articles.
 */
-(IBAction)skipFolder:(id)sender
{
	if (![db readOnly])
	{
		[articleController markAllReadByArray:[foldersTree selectedFolders] withUndo:YES withRefresh:YES];
		[self viewNextUnread:self];
	}
}

#pragma mark Marking Articles 

/* markAllRead
 * Mark all articles read in the selected folders.
 */
-(IBAction)markAllRead:(id)sender
{
	if (![db readOnly])
		[articleController markAllReadByArray:[foldersTree selectedFolders] withUndo:YES withRefresh:YES];
}

/* markAllSubscriptionsRead
 * Mark all subscriptions as read
 */
-(IBAction)markAllSubscriptionsRead:(id)sender
{
	if (![db readOnly])
	{
		[articleController markAllReadByArray:[foldersTree folders:0] withUndo:NO withRefresh:YES];
		[self clearUndoStack];
	}
}

/* markRead
 * Toggle the read/unread state of the selected articles
 */
-(IBAction)markRead:(id)sender
{
	Article * theArticle = [self selectedArticle];
	if (theArticle != nil && ![db readOnly])
	{
		NSArray * articleArray = [mainArticleView markedArticleRange];
		[articleController markReadByArray:articleArray readFlag:![theArticle isRead]];
	}
}

/* markFlagged
 * Toggle the flagged/unflagged state of the selected article
 */
-(IBAction)markFlagged:(id)sender
{
	Article * theArticle = [self selectedArticle];
	if (theArticle != nil && ![db readOnly])
	{
		NSArray * articleArray = [mainArticleView markedArticleRange];
		[articleController markFlaggedByArray:articleArray flagged:![theArticle isFlagged]];
	}
}

/* unsubscribeFeed
 * Subscribe or re-subscribe to a feed.
 */
-(IBAction)unsubscribeFeed:(id)sender
{
	NSMutableArray * selectedFolders = [NSMutableArray arrayWithArray:[foldersTree selectedFolders]];
	int count = [selectedFolders count];
	BOOL doSubscribe = NO;
	int index;

	if (count > 0)
		doSubscribe = IsUnsubscribed([selectedFolders objectAtIndex:0]);
	for (index = 0; index < count; ++index)
	{
		Folder * folder = [selectedFolders objectAtIndex:index];
		int infoFolderId = [folder itemId];

		if (doSubscribe)
			[[Database sharedDatabase] clearFolderFlag:infoFolderId flagToClear:MA_FFlag_Unsubscribed];
		else
			[[Database sharedDatabase] setFolderFlag:infoFolderId flagToSet:MA_FFlag_Unsubscribed];
		[[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_FoldersUpdated object:[NSNumber numberWithInt:infoFolderId]];
	}
}

/* renameFolder
 * Renames the current folder
 */
-(IBAction)renameFolder:(id)sender
{
	[foldersTree renameFolder:[foldersTree actualSelection]];
}

/* deleteFolder
 * Delete the current folder.
 */
-(IBAction)deleteFolder:(id)sender
{
	NSMutableArray * selectedFolders = [NSMutableArray arrayWithArray:[foldersTree selectedFolders]];
	int count = [selectedFolders count];
	int index;
	
	// Show a different prompt depending on whether we're deleting one folder or a
	// collection of them.
	NSString * alertBody = nil;
	NSString * alertTitle = nil;
	
	if (count == 1)
	{
		Folder * folder = [selectedFolders objectAtIndex:0];
		if (IsSmartFolder(folder))
		{
			alertBody = [NSString stringWithFormat:NSLocalizedString(@"Delete smart folder text", nil), [folder name]];
			alertTitle = NSLocalizedString(@"Delete smart folder", nil);
		}
		else if (IsRSSFolder(folder))
		{
			alertBody = [NSString stringWithFormat:NSLocalizedString(@"Delete RSS feed text", nil), [folder name]];
			alertTitle = NSLocalizedString(@"Delete RSS feed", nil);
		}
		else if (IsGroupFolder(folder))
		{
			alertBody = [NSString stringWithFormat:NSLocalizedString(@"Delete group folder text", nil), [folder name]];
			alertTitle = NSLocalizedString(@"Delete group folder", nil);
		}
		else if (IsTrashFolder(folder))
			return;
		else
			NSAssert1(false, @"Unhandled folder type in deleteFolder: %@", [folder name]);
	}
	else
	{
		alertBody = [NSString stringWithFormat:NSLocalizedString(@"Delete multiple folders text", nil), count];
		alertTitle = NSLocalizedString(@"Delete multiple folders", nil);
	}
	
	// Get confirmation first
	int returnCode;
	returnCode = NSRunAlertPanel(alertTitle, alertBody, NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil);
	if (returnCode == NSAlertAlternateReturn)
		return;
	
	// End any editing
	if (rssFeed != nil)
		[rssFeed doEditCancel:nil];
	if (smartFolder != nil)
		[smartFolder doCancel:nil];
	if ([(NSControl *)[foldersTree mainView] abortEditing])
		[mainWindow makeFirstResponder:[foldersTree mainView]];
	

	// Clear undo stack for this action
	[self clearUndoStack];
	
	// Prompt for each folder for now
	for (index = 0; index < count; ++index)
	{
		Folder * folder = [selectedFolders objectAtIndex:index];
		
		// This little hack is so if we're deleting the folder currently being displayed
		// and there's more than one folder being deleted, we delete the folder currently
		// being displayed last so that the MA_Notify_FolderDeleted handlers that only
		// refresh the display if the current folder is being deleted only trips once.
		if ([folder itemId] == [articleController currentFolderId] && index < count - 1)
		{
			[selectedFolders insertObject:folder atIndex:count];
			++count;
			continue;
		}
		if (!IsTrashFolder(folder))
		{
			// Create a status string
			NSString * deleteStatusMsg = [NSString stringWithFormat:NSLocalizedString(@"Delete folder status", nil), [folder name]];
			[self setStatusMessage:deleteStatusMsg persist:NO];
			
			// Now call the database to delete the folder.
			[db deleteFolder:[folder itemId]];
		}
	}
	
	// Unread count may have changed
	[self setStatusMessage:nil persist:NO];
	[self showUnreadCountOnApplicationIconAndWindowTitle];
}

/* getInfo
 * Display the Info panel for the selected feeds.
 */
-(IBAction)getInfo:(id)sender
{
	int folderId = [foldersTree actualSelection];
	if (folderId > 0)
		[[InfoWindowManager infoWindowManager] showInfoWindowForFolder:folderId];
}

/* viewSourceHomePage
 * Display the web site associated with this feed, if there is one.
 */
-(IBAction)viewSourceHomePage:(id)sender
{
	Article * thisArticle = [self selectedArticle];
	Folder * folder = (thisArticle) ? [db folderFromID:[thisArticle folderId]] : [db folderFromID:[foldersTree actualSelection]];
	if (thisArticle || IsRSSFolder(folder))
		[self openURLFromString:[folder homePage] inPreferredBrowser:YES];
}

/* updateSearchPlaceholder
 * Update the search placeholder string in the search field depending on the view in
 * the active tab.
 */
-(void)updateSearchPlaceholder
{
	switch (searchMenuTag)
	{
		case MA_Search_Selected_Folder:
			if ([[Preferences standardPreferences] layout] == MA_Layout_Unified)
			{
				[[searchField cell] setSendsWholeSearchString:YES];
#ifndef GNUSTEP
				[[searchField cell] setPlaceholderString:[articleController searchPlaceholderString]];
#endif
			}
			else
			{
				[[searchField cell] setSendsWholeSearchString:NO];
#ifndef GNUSTEP
				[[searchField cell] setPlaceholderString:[articleController searchPlaceholderString]];
#endif
			}
			return;
		case MA_Search_All:
		default:
#ifndef GNUSTEP
			[[searchField cell] setPlaceholderString: @"Search all articles"];
#endif
			return;
	}
}

#pragma mark Searching

/* setFocusToSearchField
 * Put the input focus on the search field.
 */
-(IBAction)setFocusToSearchField:(id)sender
{
	if ([self toolbarItemWithIdentifier:@"SearchItem"])
	{
		if (![[mainWindow toolbar] isVisible])
			[[mainWindow toolbar] setVisible:YES];
		[mainWindow makeFirstResponder:searchField];
	}
}

/* setSearchString
 * Sets the filter bar's search string.
 */
-(void)setSearchString:(NSString *)newSearchString
{
	[searchField setStringValue:newSearchString];
}

/* searchString
 * Return the contents of the search field.
 */
-(NSString *)searchString
{
	return [searchField stringValue];
}

/* searchUsingToolbarTextField
 * Executes a search using the search field on the toolbar.
 */
-(IBAction)searchUsingToolbarTextField:(id)sender
{
	switch(searchMenuTag)
	{
		case MA_Search_Selected_Folder:
#ifndef GNUSTEP
			[primaryView performFindPanelAction:NSFindPanelActionNext];
#endif
			return;
		case MA_Search_All:
		default:
			if (![[searchField stringValue] isBlank])
			{
				[db setSearchString:[searchField stringValue]];
				if ([foldersTree actualSelection] != [db searchFolderId])
					[foldersTree selectFolder:[db searchFolderId]];
				else
					[mainArticleView refreshFolder:MA_Refresh_ReloadFromDatabase];
			}
	}
}

#pragma mark Refresh Subscriptions

/* refreshAllFolderIcons
 * Get new favicons from all subscriptions.
 */
-(IBAction)refreshAllFolderIcons:(id)sender
{
	if (![self isConnecting])
		[[RefreshManager sharedManager] refreshFolderIconCacheForSubscriptions:[foldersTree folders:0]];
}

/* refreshAllSubscriptions
 * Get new articles from all subscriptions.
 */
-(IBAction)refreshAllSubscriptions:(id)sender
{
	// Reset the refresh timer
	[self handleCheckFrequencyChange:nil];
	
	if (![self isConnecting])
	{
		int total = [[RefreshManager sharedManager] refreshSubscriptions:[foldersTree folders:0] ignoringSubscriptionStatus:NO];		
//NSLog(@"total %d", total);
		[spinner setMaxValue: total];
	}
}

/* refreshSelectedSubscriptions
 * Refresh one or more subscriptions selected from the folders list. The selection we obtain
 * may include non-RSS folders so these have to be trimmed out first.
 */
-(IBAction)refreshSelectedSubscriptions:(id)sender
{
	int total = [[RefreshManager sharedManager] refreshSubscriptions:[foldersTree selectedFolders] ignoringSubscriptionStatus:YES];
	[spinner setMaxValue: total];
}

/* cancelAllRefreshes
 * Used to kill all active refresh connections and empty the queue of folders due to
 * be refreshed.
 */
-(IBAction)cancelAllRefreshes:(id)sender
{
	[[RefreshManager sharedManager] cancelAll];
}

/* makeTextSmaller
 * Make text size smaller in the article pane.
 * In the future, we may want this to make text size smaller in the article list instead.
 */
-(IBAction)makeTextSmaller:(id)sender
{
#if 0 // FIXME
	[[primaryView webView] makeTextSmaller:sender];
#endif
}

/* makeTextLarger
 * Make text size larger in the article pane.
 * In the future, we may want this to make text size larger in the article list instead.
 */
-(IBAction)makeTextLarger:(id)sender
{
#if 0 // FIXME
	[[primaryView webView] makeTextLarger:sender];
#endif
}

#if 0 // NOT_USED
/* changeFiltering
 * Refresh the filtering of articles.
 */
-(IBAction)changeFiltering:(id)sender
{
	NSMenuItem * menuItem = (NSMenuItem *)sender;
	[[Preferences standardPreferences] setFilterMode:[menuItem tag]];
}
#endif

#pragma mark Progress Indicator 

/* startProgressIndicator
 * Gets the progress indicator on the info bar running. Because this can be called
 * nested, we use progressCount to make sure we remove it at the right time.
 */
-(void)startProgressIndicator
{
	if (progressCount++ == 0)
	{
		[spinner startAnimation:self];
		[spinner setHidden: NO];
	}
}

/* stopProgressIndicator
 * Stops the progress indicator on the info bar running
 */
-(void)stopProgressIndicator
{
	NSAssert(progressCount > 0, @"Called stopProgressIndicator without a matching startProgressIndicator");
	if (--progressCount < 1)
	{
		[spinner stopAnimation:self];
		[spinner setHidden: YES];
		progressCount = 0;
	}
}

#pragma mark Status Bar

/* isStatusBarVisible
 * Simple function that returns whether or not the status bar is visible.
 */
-(BOOL)isStatusBarVisible
{
	Preferences * prefs = [Preferences standardPreferences];
	return [prefs showStatusBar];
}

/* handleShowStatusBar
 * Respond to the status bar state being changed programmatically.
 */
-(void)handleShowStatusBar:(NSNotification *)nc
{
	[self setStatusBarState:[[Preferences standardPreferences] showStatusBar] withAnimation:YES];
}

/* handleRefreshingProgress
 * Receive notification for number of refreshing folders.
 */
- (void) handleRefreshingProgress: (NSNotification *) nc
{
	int progress = [[nc object] intValue];
//NSLog(@"progress %d", progress);
	if (progress > -1)
	{
		if (progress > [spinner maxValue])
		{
			[spinner setMaxValue: progress];
		}
		[spinner setDoubleValue: ([spinner maxValue] - progress)];
		// For some reason, it may not be updated if not focused
		// [spinner setNeedsDisplay: YES];
	}
}

/* showHideStatusBar
 * Toggle the status bar on/off. When off, expand the article area to fill the space.
 */
-(IBAction)showHideStatusBar:(id)sender
{
	BOOL newState = ![self isStatusBarVisible];

	[self setStatusBarState:newState withAnimation:YES];
	[[Preferences standardPreferences] setShowStatusBar:newState];
}

/* setStatusBarState
 * Show or hide the status bar state. Does not persist the state - use showHideStatusBar for this.
 */
-(void)setStatusBarState:(BOOL)isVisible withAnimation:(BOOL)doAnimate
{
	NSRect viewSize = [splitView1 frame];
	if (isStatusBarVisible && !isVisible)
	{
		viewSize.size.height += MA_StatusBarHeight;
		viewSize.origin.y -= MA_StatusBarHeight;
	}
	else if (!isStatusBarVisible && isVisible)
	{
		viewSize.size.height -= MA_StatusBarHeight;
		viewSize.origin.y += MA_StatusBarHeight;
	}
	if (isStatusBarVisible != isVisible)
	{
		if (!doAnimate)
		{
			[statusText setHidden:!isVisible];
			[splitView1 setFrame:viewSize];
		}
		else
		{
			if (!isVisible)
			{
				// When hiding the status bar, hide these controls BEFORE
				// we start hiding the view. Looks cleaner.
				[statusText setHidden:YES];
			}
			[splitView1 resizeViewWithAnimation:viewSize withTag:MA_ViewTag_Statusbar];
		}
		[mainWindow display];
		isStatusBarVisible = isVisible;
	}
}

/* setStatusMessage
 * Sets a new status message for the status bar then updates the view. To remove
 * any existing status message, pass nil as the value.
 */
-(void)setStatusMessage:(NSString *)newStatusText persist:(BOOL)persistenceFlag
{
	if (persistenceFlag)
	{
		[newStatusText retain];
		[persistedStatusText release];
		persistedStatusText = newStatusText;
	}
	if (newStatusText == nil || [newStatusText isBlank])
		newStatusText = persistedStatusText;
	[statusText setStringValue:(newStatusText ? newStatusText : @"")];
}
#ifndef GNUSTEP
/* viewAnimationCompleted
 * Called when animation of the specified view completes.
 */
-(void)viewAnimationCompleted:(NSView *)theView withTag:(int)viewTag
{
	if (viewTag == MA_ViewTag_Statusbar && [self isStatusBarVisible])
	{
		// When showing the status bar, show these controls AFTER
		// we have made the view visible. Again, looks cleaner.
		[statusText setHidden:NO];
		return;
	}
}
#endif
#pragma mark Toolbar And Menu Bar Validation

/* validateCommonToolbarAndMenuItems
 * Validation code for items that appear on both the toolbar and the menu. Since these are
 * handled identically, we validate here to avoid duplication of code in two delegates.
 * The return value is YES if we handled the validation here and no further validation is
 * needed, NO otherwise.
 */
-(BOOL)validateCommonToolbarAndMenuItems:(SEL)theAction validateFlag:(BOOL *)validateFlag
{
	BOOL isMainWindowVisible = [mainWindow isVisible];
	BOOL isAnyArticleView = YES;

	if ((theAction == @selector(refreshAllSubscriptions:)) || (theAction == @selector(refreshAllFolderIcons:)))
	{
		*validateFlag = ![self isConnecting] && ![db readOnly];
		return YES;
	}
	if (theAction == @selector(newSubscription:))
	{
		*validateFlag = ![db readOnly] && isMainWindowVisible;
		return YES;
	}
	if (theAction == @selector(newSmartFolder:))
	{
		*validateFlag = ![db readOnly] && isMainWindowVisible;
		return YES;
	}
	if (theAction == @selector(skipFolder:))
	{
		*validateFlag = ![db readOnly] && isAnyArticleView && isMainWindowVisible && [db countOfUnread] > 0;
		return YES;
	}
	if (theAction == @selector(emptyTrash:))
	{
		*validateFlag = ![db readOnly];
		return YES;
	}
	if (theAction == @selector(setLayoutFromToolbar:))
	{
		*validateFlag = isMainWindowVisible;
		return YES;
	}
	return NO;
}

/* validateToolbarItem
 * Check [theItem identifier] and return YES if the item is enabled, NO otherwise.
 */
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
	BOOL flag;
	[self validateCommonToolbarAndMenuItems: [toolbarItem action] 
	                           validateFlag: &flag];
	return flag;
}

/* validateMenuItem
 * This is our override where we handle item validation for the
 * commands that we own.
 */
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL	theAction = [menuItem action];
	BOOL isMainWindowVisible = [mainWindow isVisible];
	BOOL isAnyArticleView = YES;
	BOOL isArticleView = primaryView == mainArticleView;
	BOOL flag;
	
	if ([self validateCommonToolbarAndMenuItems:theAction validateFlag:&flag])
	{
		return flag;
	}
	if (theAction == @selector(printDocument:))
	{
		return ([self selectedArticle] != nil && isMainWindowVisible);
	}
	else if (theAction == @selector(goBack:))
	{
		return [primaryView canGoBack] && isMainWindowVisible;
	}
	else if (theAction == @selector(goForward:))
	{
		return [primaryView canGoForward] && isMainWindowVisible;
	}
	else if (theAction == @selector(newGroupFolder:))
	{
		return ![db readOnly] && isMainWindowVisible;
	}
	else if (theAction == @selector(viewNextUnread:))
	{
		return [db countOfUnread] > 0;
	}
	else if (theAction == @selector(showHideStatusBar:))
	{
		if ([self isStatusBarVisible])
			[menuItem setTitle:NSLocalizedString(@"Hide Status Bar", nil)];
		else
			[menuItem setTitle:NSLocalizedString(@"Show Status Bar", nil)];
		return isMainWindowVisible;
	}
#if 0 // FIXME
	else if (theAction == @selector(makeTextLarger:))
	{
		return [[primaryView webView] canMakeTextLarger] && isMainWindowVisible;
	}
	else if (theAction == @selector(makeTextSmaller:))
	{
		return [[primaryView webView] canMakeTextSmaller] && isMainWindowVisible;
	}
#endif
	else if (theAction == @selector(doViewColumn:))
	{
		Field * field = [menuItem representedObject];
		[menuItem setState:[field visible] ? NSOnState : NSOffState];
		return isMainWindowVisible && isArticleView;
	}
	else if (theAction == @selector(doSelectStyle:))
	{
		NSString * styleName = [menuItem title];
		[menuItem setState:[styleName isEqualToString:[[Preferences standardPreferences] displayStyle]] ? NSOnState : NSOffState];
		return isMainWindowVisible && isAnyArticleView;
	}
	else if (theAction == @selector(doSortColumn:))
	{
		Field * field = [menuItem representedObject];
		if ([[field name] isEqualToString:[articleController sortColumnIdentifier]])
			[menuItem setState:NSOnState];
		else
			[menuItem setState:NSOffState];
		return isMainWindowVisible && isAnyArticleView;
	}
	else if (theAction == @selector(unsubscribeFeed:))
	{
		Folder * folder = [db folderFromID:[foldersTree actualSelection]];
		if (folder)
		{
			if (IsUnsubscribed(folder))
				[menuItem setTitle:NSLocalizedString(@"Resubscribe", nil)];
			else
				[menuItem setTitle:NSLocalizedString(@"Unsubscribe", nil)];
		}
		return folder && IsRSSFolder(folder) && ![db readOnly] && isMainWindowVisible;
	}
	else if (theAction == @selector(deleteFolder:))
	{
		Folder * folder = [db folderFromID:[foldersTree actualSelection]];
		return folder && !IsTrashFolder(folder) && !IsSearchFolder(folder) && ![db readOnly] && isMainWindowVisible;
	}
	else if (theAction == @selector(refreshSelectedSubscriptions:))
	{
		Folder * folder = [db folderFromID:[foldersTree actualSelection]];
		return folder && (IsRSSFolder(folder) || IsGroupFolder(folder)) && ![db readOnly];
	}
	else if (theAction == @selector(renameFolder:))
	{
		Folder * folder = [db folderFromID:[foldersTree actualSelection]];
		return folder && ![db readOnly] && isMainWindowVisible;
	}
	else if (theAction == @selector(markAllRead:))
	{
		Folder * folder = [db folderFromID:[foldersTree actualSelection]];
		return folder && !IsTrashFolder(folder) && ![db readOnly] && isArticleView && isMainWindowVisible && [db countOfUnread] > 0;
	}
	else if (theAction == @selector(markAllSubscriptionsRead:))
	{
		return ![db readOnly] && isMainWindowVisible && [db countOfUnread] > 0;
	}
	else if (theAction == @selector(importSubscriptions:))
	{
		return ![db readOnly] && isMainWindowVisible;
	}
	else if (theAction == @selector(cancelAllRefreshes:))
	{
		return [self isConnecting];
	}
	else if (theAction == @selector(viewSourceHomePage:))
	{
		Article * thisArticle = [self selectedArticle];
		Folder * folder = (thisArticle) ? [db folderFromID:[thisArticle folderId]] : [db folderFromID:[foldersTree actualSelection]];
		return folder && (thisArticle || IsRSSFolder(folder)) && ([folder homePage] && ![[folder homePage] isBlank] && isMainWindowVisible && isArticleView);
	}
	else if (theAction == @selector(viewArticlePage:))
	{
		Article * thisArticle = [self selectedArticle];
		if (thisArticle != nil)
			return ([thisArticle link] && ![[thisArticle link] isBlank] && isMainWindowVisible && isArticleView);
		return NO;
	}
	else if (theAction == @selector(exportSubscriptions:))
	{
		return isMainWindowVisible;
	}
	else if (theAction == @selector(compactDatabase:))
	{
		return ![self isConnecting] && ![db readOnly] && isMainWindowVisible;
	}
	else if (theAction == @selector(editFolder:))
	{
		Folder * folder = [db folderFromID:[foldersTree actualSelection]];
		return folder && (IsSmartFolder(folder) || IsRSSFolder(folder)) && ![db readOnly] && isMainWindowVisible;
	}
	else if (theAction == @selector(getInfo:))
	{
		Folder * folder = [db folderFromID:[foldersTree actualSelection]];
		return IsRSSFolder(folder) && isMainWindowVisible;
	}
	else if (theAction == @selector(restoreMessage:))
	{
		Folder * folder = [db folderFromID:[foldersTree actualSelection]];
		return IsTrashFolder(folder) && [self selectedArticle] != nil && ![db readOnly] && isMainWindowVisible && isArticleView;
	}
	else if (theAction == @selector(deleteMessage:))
	{
		return [self selectedArticle] != nil && ![db readOnly] && isMainWindowVisible && isArticleView;
	}
#if 0 // NOT_USED
	else if (theAction == @selector(changeFiltering:))
	{
		[menuItem setState:([menuItem tag] == [[Preferences standardPreferences] filterMode]) ? NSOnState : NSOffState];
		return isMainWindowVisible;
	}
#endif
	else if (theAction == @selector(setFocusToSearchField:))
	{
		return isMainWindowVisible;
	}
	else if (theAction == @selector(reportLayout:))
	{
		Preferences * prefs = [Preferences standardPreferences];
		[menuItem setState:([prefs layout] == MA_Layout_Report) ? NSOnState : NSOffState];
		return isMainWindowVisible;
	}
	else if (theAction == @selector(condensedLayout:))
	{
		Preferences * prefs = [Preferences standardPreferences];
		[menuItem setState:([prefs layout] == MA_Layout_Condensed) ? NSOnState : NSOffState];
		return isMainWindowVisible;
	}
	else if (theAction == @selector(unifiedLayout:))
	{
		Preferences * prefs = [Preferences standardPreferences];
		[menuItem setState:([prefs layout] == MA_Layout_Unified) ? NSOnState : NSOffState];
		return isMainWindowVisible;
	}
	else if (theAction == @selector(markFlagged:))
	{
		Article * thisArticle = [self selectedArticle];
		if (thisArticle != nil)
		{
			if ([thisArticle isFlagged])
				[menuItem setTitle:NSLocalizedString(@"Mark Unflagged", nil)];
			else
				[menuItem setTitle:NSLocalizedString(@"Mark Flagged", nil)];
		}
		return (thisArticle != nil && ![db readOnly] && isMainWindowVisible && isArticleView);
	}
	else if (theAction == @selector(markRead:))
	{
		Article * thisArticle = [self selectedArticle];
		if (thisArticle != nil)
		{
			if ([thisArticle isRead])
				[menuItem setTitle:NSLocalizedString(@"Mark Unread", nil)];
			else
				[menuItem setTitle:NSLocalizedString(@"Mark Read", nil)];
		}
		return (thisArticle != nil && ![db readOnly] && isMainWindowVisible && isArticleView);
	}
	else if (theAction == @selector(downloadEnclosure:))
	{
		if ([[mainArticleView markedArticleRange] count] > 1)
			[menuItem setTitle:NSLocalizedString(@"Download Enclosures", nil)];
		else
			[menuItem setTitle:NSLocalizedString(@"Download Enclosure", nil)];
		return ([[self selectedArticle] hasEnclosure] && isMainWindowVisible);
	}
	else if (theAction == @selector(newTab:))
	{
		return isMainWindowVisible;
	}	
	return YES;
}

/* itemForItemIdentifier
 * This method is required of NSToolbar delegates.  It takes an identifier, and returns the matching ToolbarItem.
 * It also takes a parameter telling whether this toolbar item is going into an actual toolbar, or whether it's
 * going to be displayed in a customization palette.
 */
- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
      itemForItemIdentifier: (NSString *) itemIdentifier
  willBeInsertedIntoToolbar: (BOOL) willBeInserted
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	if ([itemIdentifier isEqualToString:@"SearchItem"])
	{
		[item setView:searchView];
		[item setLabel:NSLocalizedString(@"Search Articles", nil)];
		[item setPaletteLabel:[item label]];
		[item setTarget:self];
		[item setAction:@selector(searchUsingToolbarTextField:)];
		[item setToolTip:NSLocalizedString(@"Search Articles", nil)];
		[item setMinSize: [searchView frame].size];
		[item setMaxSize: [searchView frame].size];
	}
	else if ([itemIdentifier isEqualToString:@"Subscribe"])
	{
		[item setLabel:NSLocalizedString(@"Subscribe", nil)];
		[item setPaletteLabel:[item label]];
		[item setImage: [NSImage imageNamed: @"subscribeButton"]];
		[item setTarget:self];
		[item setAction:@selector(newSubscription:)];
		[item setToolTip:NSLocalizedString(@"Create a new subscription", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"SkipFolder"])
	{
		[item setLabel:NSLocalizedString(@"Skip Folder", nil)];
		[item setPaletteLabel:[item label]];
		[item setImage: [NSImage imageNamed: @"skipFolderButton"]];
		[item setTarget:self];
		[item setAction:@selector(skipFolder:)];
		[item setToolTip:NSLocalizedString(@"Skip Folder", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"Refresh"])
	{
		[item setLabel:NSLocalizedString(@"Refresh", nil)];
		[item setPaletteLabel:[item label]];
		[item setImage: [NSImage imageNamed: @"refreshButton"]];
		[item setTarget:self];
		[item setAction:@selector(refreshAllSubscriptions:)];
		[item setToolTip:NSLocalizedString(@"Refresh all your subscriptions", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"EmptyTrash"])
	{
		[item setLabel:NSLocalizedString(@"Empty Trash", nil)];
		[item setPaletteLabel:[item label]];
		[item setImage: [NSImage imageNamed: @"emptyTrashButton"]];
		[item setTarget:self];
		[item setAction:@selector(emptyTrash:)];
		[item setToolTip:NSLocalizedString(@"Delete all articles in the trash", nil)];
	}
	return [item autorelease];
}

/* toolbarDefaultItemIdentifiers
 * This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
 * set of toolbar items.  It can also be called by the customization palette to display the default toolbar.
 */
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		@"Subscribe",
		@"SkipFolder",
		@"Refresh",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"SearchItem",
		nil];
}

/* toolbarAllowedItemIdentifiers
 * This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
 * toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
 */
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		@"Refresh",
		@"Subscribe",
		@"SkipFolder",
		@"EmptyTrash",
		@"SearchItem",
		nil];
}

/* dealloc
 * Clean up and release resources.
 */
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[standardURLs release];
	[downloadWindow release];
	[persistedStatusText release];
	[originalIcon release];
	[smartFolder release];
	[rssFeed release];
	[groupFolder release];
	[preferenceController release];
	[activityViewer release];
	[checkTimer release];
	[db release];
	[searchView release];
	[mainArticleView release];
	[unifiedListView release];
	[articleController release];
	[mainWindow release];
	[super dealloc];
}
@end
