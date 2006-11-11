/* 
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen
   Copyright (C) 2005, 2006 Guenther Noack

   Author: Yen-Ju Chen
   Author: Guenther Noack,,,

   Created: 2005-03-25 19:42:31 +0100 by guenther
   
   Application Controller

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
 
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "Controller.h"
#import "MainWindow.h"
#import "FeedList.h"
#import "RSSReaderFeed.h"
#import "SubscriptionPanelController.h"
#import "FetchingProgressManager.h"
#if 0
#import "RSSReaderService.h"
#endif
#import "Global.h"
#import "GNUstep.h"
#import "ContentTextView.h"
#import "PreferencePane.h"

static Controller *sharedInstance;

@implementation Controller

+ (Controller *) mainController
{
  if (sharedInstance == nil) {
    sharedInstance = [[Controller alloc] init];
  }
  return sharedInstance;
}

- (id) init
{
  self = [super init];
  return self;
}

- (void) dealloc
{
  DESTROY(feedList);
  [super dealloc];
}

- (void)awakeFromNib
{
  /* This will be called multiple times because interfaces are loaded
   * multiple times 
   */
}

- (void)applicationWillFinishLaunching: (NSNotification *) not
{
  /* Create pane as early as possible for logging */
  paneController = [[PaneController alloc] initWithRegistry: AUTORELEASE([[PKPaneRegistry alloc] init])
                       presentationMode: PKMatrixPresentationMode
                       owner: nil];

  ASSIGN(feedList, [FeedList feedList]);

  /* Make sure defaults are properly set */
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults objectForKey: RSSReaderWebBrowserDefaults] == nil) {
    [defaults setObject: @"/usr/bin/firefox"
              forKey: RSSReaderWebBrowserDefaults];
  }

  int number = [defaults integerForKey: RSSReaderRemoveArticlesAfterDefaults];
  if (number == 0) {
    /* Not set */
    [defaults setInteger: 7 forKey: RSSReaderRemoveArticlesAfterDefaults];
  }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
  /* Remove old articles */
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  int number = [defaults integerForKey: RSSReaderRemoveArticlesAfterDefaults];
  if (number > 0) {
    [feedList removeArticlesOlderThanDay: number];
  }

  /* Toolbar */
  NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: RSSReaderToolbarIdentifier];
  [toolbar setDelegate: mainWindow];
  [mainWindow setToolbar: toolbar];
  RELEASE(toolbar);

  /* Progress Bar */
  [progressBar setHidden: YES];
  [progressBar setIndeterminate: NO];

  [mainWindow setFrameAutosaveName: RSSReaderMainWindowFrameName];

  [feedBookmarkView setDisplayProperties: [NSArray arrayWithObject: kBKBookmarkTitleProperty]];
  [[feedBookmarkView outlineView] setDelegate: self];
  [feedBookmarkView setBookmarkStore: [feedList feedStore]];

  [[articleCollectionView tableView] setDelegate: self];
  [articleCollectionView setDisplayProperties: [NSArray arrayWithObject: kArticleHeadlineProperty]];
  [articleCollectionView setSortingProperty: kArticleDateProperty reverse: YES];
  [articleCollectionView setCollection: [feedList articleCollection]];

  searchField = [mainWindow searchField];
#if 0
  /* Register service... */
  [NSApp setServicesProvider: [[RSSReaderService alloc] init]];
#endif
  [feedBookmarkView reloadData];
  [articleCollectionView reloadData];

  /* Resize bookmark view from saved size */
  NSString *s = [defaults stringForKey: RSSReaderBookmarkViewFrameDefaults];
  if (s) {
    NSRect rect = NSRectFromString(s);
    [feedBookmarkView setFrameSize: rect.size];
    NSView *view = [[[feedBookmarkView superview] subviews] objectAtIndex: 1];
    rect.size.width = [[feedBookmarkView superview] bounds].size.width - rect.size.width;
    [view setFrameSize: rect.size];
  }

  /* Listen to RSSFeedFetchedNotification for loading in backgroun */
  [[NSNotificationCenter defaultCenter]
          addObserver: self 
          selector: @selector(feedFetched:)
          name: RSSFeedFetchedNotification
          object: nil];
  [[NSNotificationCenter defaultCenter]
          addObserver: self
          selector: @selector(feedFetchFailed:)
          name: RSSFeedFetchFailedNotification
          object: nil];

}

- (BOOL)applicationShouldTerminate:(id)sender
{
  [feedList save];
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotif
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  /* Save bookmar view size */
  NSRect rect = [feedBookmarkView frame];
  [defaults setObject: NSStringFromRect(rect)
            forKey: RSSReaderBookmarkViewFrameDefaults];
  [defaults synchronize];
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
  [feedList addFeedWithURL: [NSURL fileURLWithPath: fileName]];
  return YES;
}

- (void) showPreferences: (id) sender
{
  if (preferencesController == nil) {
    /* Initialize here */
    /* Automatically register into PKPreferencePaneRegistry */
    AUTORELEASE([[PreferencePane alloc] init]);
    ASSIGN(preferencesController, [PKPreferencesController sharedPreferencesController]);
    [preferencesController setPresentationMode: PKPlainPresentationMode];
  }
  [(NSWindow *)[preferencesController owner] setTitle: @"Preferences"];
  [(NSWindow *)[preferencesController owner] makeKeyAndOrderFront: self];
}

- (void) subscribe: (id) sender
{
  SubscriptionPanelController *controller = 
	  [SubscriptionPanelController subscriptionPanelController];

  int result = [controller runPanelInModal];
  if (result == NSOKButton) {

    NSURL *url = [controller url];

    // create the feed
    RSSFeed *feed = AUTORELEASE([[RSSReaderFeed alloc] initWithURL: url]);
    [feed setAutoClear: NO];
    /* Set temparory name */
    [feed setFeedName: [url absoluteString]];

    // actually add the feed
    [feedList addFeed: feed];

    [feedBookmarkView reloadData];
    [articleCollectionView reloadData];
  }
}

/** Private **/
- (void) removeGroupRecursive: (BKGroup *) g
{ 
  NSEnumerator *e = nil; 
  BKBookmark *bk = nil;
  BKGroup *subg = nil;
  e = [[g subgroups] objectEnumerator];
  while ((subg = [e nextObject])) {
    [self removeGroupRecursive: subg];
  }
  e = [[g items] objectEnumerator];
  while((bk = [e nextObject])) {
    RSSFeed *feed = [feedList feedForURL: [bk URL]];
    [feedList removeFeed: feed];
    [[feedList feedStore] removeBookmark: bk];
  }
  if ([[feedList feedStore] removeRecord: g] == NO) {
    NSLog(@"Fail to remove %@(%@)", g, [g valueForProperty: kBKGroupNameProperty]);
  }
}
/** End of Private **/

- (void) delete: (id) sender
{
  int index = [[feedBookmarkView outlineView] selectedRow];
  if (index > -1) {
    id item = [[feedBookmarkView outlineView] itemAtRow: index];
    if ([item isKindOfClass: [BKBookmark class]]) {
      BKBookmark *bk = (BKBookmark *) item;
      RSSFeed *feed = [feedList feedForURL: [bk URL]];
      [feedList removeFeed: feed];
    } else if ([item isKindOfClass: [BKGroup class]]) {
      int result = NSRunAlertPanel(_(@"Remove feeds"), _(@"All needs under this group will be removed. Are you sure ?"), _(@"Cancel"), _(@"Remove"), nil, nil);
      if (result == NSAlertAlternateReturn) {
        [self removeGroupRecursive: (BKGroup *) item];
      }
    }
    [feedBookmarkView reloadData];
    [[feedBookmarkView outlineView] deselectAll: self];
    [articleCollectionView reloadData];
  }
}

- (void) reload: (id) sender
{
  int index = [[feedBookmarkView outlineView] selectedRow];
  if (index > -1) {
    /* Setup progress bar */
    [progressBar setHidden: NO];
    [progressBar setMinValue: 0];
    [progressBar setMaxValue: 1];
    [progressBar setDoubleValue: 0.5];
    [progressBar startAnimation: self];

    BKBookmark *bk = [[feedBookmarkView outlineView] itemAtRow: index];
    RSSFeed *feed = [feedList feedForURL: [bk URL]];
    [[FetchingProgressManager defaultManager] fetchFeeds: [NSArray arrayWithObject: feed]];
  }
}

- (void) reloadAll: (id) sender
{
  [progressBar setHidden: NO];
  [progressBar setMinValue: 0];
  [progressBar setMaxValue: [[feedList feedList] count]];
  [progressBar setDoubleValue: 0];
  [progressBar startAnimation: self];

  [[FetchingProgressManager defaultManager] fetchFeeds: [feedList feedList]];
}

- (void) addGroup: (id) sender
{
  BKGroup *group = [[BKGroup alloc] init];
  [group setValue: @"New Group" forProperty: kBKGroupNameProperty];
  [[feedList feedStore] addRecord: group];
  DESTROY(group);
  [feedBookmarkView reloadData];
}

- (void) markAllRead: (id) sender
{
  [articleCollectionView beginEditing];
  int i;
  for (i = 0; i < [articleCollectionView numberOfItems]; i++) {
    id item = [articleCollectionView itemAtIndex: i];
    if ([item isKindOfClass: [CKItem class]]) {
      [(CKItem *)item setValue: [NSNumber numberWithInt: 1]
                   forProperty: kArticleReadProperty];
    }
  }
  [articleCollectionView endEditing];
  /* This change unread number. Therefore, reload bookmark view */
  [feedBookmarkView reloadData];
  [articleCollectionView reloadData];
}

- (void) markAllUnread: (id) sender
{
  [articleCollectionView beginEditing];
  int i;
  for (i = 0; i < [articleCollectionView numberOfItems]; i++) {
    id item = [articleCollectionView itemAtIndex: i];
    if ([item isKindOfClass: [CKItem class]]) {
      [(CKItem *)item setValue: [NSNumber numberWithInt: 0]
                   forProperty: kArticleReadProperty];
    }
  }
  [articleCollectionView endEditing];
  [feedBookmarkView reloadData];
  [articleCollectionView reloadData];
}

- (void) markRead: (id) sender
{
  int index = [[articleCollectionView tableView] selectedRow];
  if (index > -1) {
    id item = [articleCollectionView itemAtIndex: index];
    if ([item isKindOfClass: [CKItem class]]) {
      [(CKItem *)item setValue: [NSNumber numberWithInt: 1]
                   forProperty: kArticleReadProperty];
      [feedBookmarkView reloadData];
      [articleCollectionView reloadData];
    }
  }
}

- (void) markUnread: (id) sender
{
  int index = [[articleCollectionView tableView] selectedRow];
  if (index > -1) {
    id item = [articleCollectionView itemAtIndex: index];
    if ([item isKindOfClass: [CKItem class]]) {
      [(CKItem *)item setValue: [NSNumber numberWithInt: 0]
                   forProperty: kArticleReadProperty];
      [feedBookmarkView reloadData];
      [articleCollectionView reloadData];
    }
  }
}

- (void) showMainWindow: (id) sender
{
  [mainWindow makeKeyAndOrderFront: sender];
}

- (void) showLog: (id) sender
{
  [[paneController owner] makeKeyAndOrderFront: sender];
}

- (void) search: (id) sender
{
  NSString *value = [searchField stringValue];
  if ((value == nil) || ([value length] == 0)) {
    /* Remove search element */
    [articleCollectionView setSearchElement: nil];
  } else {
    /* Currently, search on headline and description */
    CKSearchElement *e1, *e2, *element;
    e1 = [CKItem searchElementForProperty: kArticleHeadlineProperty
                        label: nil
                        key: nil
                        value: value
			comparison: CKContainsSubStringCaseInsensitive];
    e2 = [CKItem searchElementForProperty: kArticleDescriptionProperty
                        label: nil
                        key: nil
                        value: value
			comparison: CKContainsSubStringCaseInsensitive];
    element = [CKSearchElement searchElementForConjunction: CKSearchOr
                             children: [NSArray arrayWithObjects: e1, e2, nil]];
    [articleCollectionView setSearchElement: element];
  }
  [articleCollectionView reloadData];
}

/** BKBookmarkView Delegate */
- (BOOL) outlineView: (NSOutlineView *) outlineView
         shouldSelectItem: (id) item
{
  if ([item isKindOfClass: [BKBookmark class]]) {
    RSSFeed *feed = [feedList feedForURL: [(BKBookmark *)item URL]];
    CKGroup *group = [feedList articleGroupForURL: [feed feedURL]];
    [articleCollectionView setRoot: group];
    [articleCollectionView reloadData];
  } else if ([item isKindOfClass: [BKGroup class]]) {
    NSEnumerator *e = [[[feedList feedStore] itemsUnderGroup: (BKGroup *)item] objectEnumerator];
    BKBookmark *bk = nil;
    NSURL *url = nil;
    NSMutableArray *array = AUTORELEASE([[NSMutableArray alloc] init]);
    while ((bk = [e nextObject])) {
      url = [bk URL];
      [array addObject: [feedList articleGroupForURL: url]];
    }
    [articleCollectionView setRoot: array];
    [articleCollectionView reloadData];
  }
  /* When feed view is selected, unselect in article view.
   * Otherwise, the selection in article view will not match
   * the content of content view.
   * And when user select the same row in article view,
   * because of the row doesn't change, it will not trigger a refresh
   * of content view. */
  [[articleCollectionView tableView] deselectAll: self];
  return YES;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView
         shouldEditTableColumn: (NSTableColumn *) tableColumn
         item: (id) item
{
  if ([item isKindOfClass: [BKGroup class]]) {
    return YES;
  }
  return NO;
}

/** Article Table View Delegate */
// is executed when something is clicked
-(BOOL) tableView: (NSTableView*) tableView
        shouldSelectRow: (int) rowIndex
{
  id item = [articleCollectionView itemAtIndex: rowIndex];
  if ([item isKindOfClass: [CKItem class]]) {
    [contentTextView setItem: item];
    if ([[item valueForProperty: kArticleReadProperty] intValue] == 0)
    {
      [item setValue: [NSNumber numberWithInt: 1]
            forProperty: kArticleReadProperty];
      [feedBookmarkView reloadData];
    }
    return YES;
  } 
  return NO;
}

// changes boldness and color
- (void) tableView: (NSTableView*) tableView
         willDisplayCell: (id) cell
         forTableColumn: (NSTableColumn*) aTableColumn
         row: (int) rowIndex
{
  id item = [articleCollectionView itemAtIndex: rowIndex];
  if ([item isKindOfClass: [CKItem class]]) {
    if ([[item valueForProperty: kArticleReadProperty] intValue] == 0) {
      [cell setFont: [NSFont boldSystemFontOfSize: [NSFont systemFontSize]]];
    } else {
      [cell setFont: [NSFont systemFontOfSize: [NSFont systemFontSize]]];
    }
  } 
}

- (void) enterKeyDownInTableView: (NSTableView *) tableView
{
  int index = [tableView selectedRow];
  if (index > -1) {
    id item = [articleCollectionView itemAtIndex: index];
    if ([item isKindOfClass: [CKItem class]]) {
      NSString *urlString = [item valueForProperty: kArticleURLProperty];
      if (urlString) {
        NSURL *url = [NSURL URLWithString: urlString];
        [[NSWorkspace sharedWorkspace] openURL: url];
      }
    }
  }
}

@end

@implementation Controller (Private)

- (void) updateProgressBar
{
  /* Increase one and stop if full */
  [progressBar incrementBy: 1];
  if ([progressBar doubleValue] == [progressBar maxValue]) {
    [progressBar setHidden: YES];
    [progressBar stopAnimation: self];
  }
}

- (void) feedFetched: (NSNotification *) not
{
  NSLog(@"feedFetched");
  CREATE_AUTORELEASE_POOL(x);
  /* This update article collection for each feed. */
  [articleCollectionView beginEditing];
  [feedList updateFeed: [not object]];
  [articleCollectionView endEditing];

  [self updateProgressBar];
  [feedBookmarkView reloadData];
  [articleCollectionView reloadData];
  DESTROY(x);
  NSLog(@"feedFetched done");
}

- (void) feedFetchFailed: (NSNotification *) not
{
  [self updateProgressBar];
}

@end
