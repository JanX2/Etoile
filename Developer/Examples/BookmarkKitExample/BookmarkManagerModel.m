#import <AppKit/AppKit.h>
#import "BookmarkManagerModel.h"
#import <BookmarkKit/BookmarkKit.h>
#import "BKTableView.h"
#import "BKBookmarkView.h"
#import "GNUstep.h"

@implementation BookmarkManagerModel

- (void) setBookmarkStore: (BKBookmarkStore *) store
{
  ASSIGN(bookmarkStore, store);
  [bookmarkView setBookmarkStore: store];
  [bookmarkView setDisplayProperties: [NSArray arrayWithObjects: kBKBookmarkTitleProperty, kBKBookmarkURLProperty, nil]];
}

- (BKBookmarkStore *) bookmarkStore
{
  return bookmarkStore;
}

- (void) setTableView: (BKTableView *) tv 
{
  tableView = tv; // not retained
}

- (void) setBookmarkView: (BKBookmarkView *) bv
{
  bookmarkView = bv; // not retained
}

- (id) init
{
  self = [super init];

  return self;
}

- (void) dealloc
{
  [super dealloc];
}

/** Controller */
- (void) addGroup: (id) sender
{
  BKOutlineView *ov = [bookmarkView outlineView];
  int selectedRow = [ov selectedRow];
  BKGroup *group = [[BKGroup alloc] init];
  [group setValue: @"New Group" forProperty: kBKGroupNameProperty];
  [bookmarkStore addRecord: group];
  BKGroup *parent = nil;
  if (selectedRow != NSNotFound) {
    id item = [ov itemAtRow: selectedRow];
    if ([item isKindOfClass: [BKGroup class]]) {
      parent = (BKGroup *)item;
    } else if ([item isKindOfClass: [BKBookmark class]]) {
      if ([(BKBookmark *)item isTopLevel] == BKNotTopLevel) {
        parent = [[(BKBookmark *) item parentGroups] objectAtIndex: 0];
      }
    }
  }
  if (parent) {
    [parent addSubgroup: group];
  } 
  [bookmarkView reloadData];
  if (parent) {
    [ov expandItem: parent];
  }
}

- (void) removeGroup: (id) sender
{
}

- (void) addBookmark: (id) sender
{
#if 0
  NSView *activeView = [self activeView];
  if (activeView == tableView) {
  } else if (activeView == outlineView) {
    int index = [outlineView selectedRow];
    if (index == NSNotFound)
      return;
    id item = [outlineView itemAtRow: index];
    BKGroup *parent;
    if (item == nil) {
      parent = [self selectedGroupInTableView];
    } else if ([item isKindOfClass: [BKBookmark class]]) {
      parent = [self selectedGroupInTableView];
    } else if ([item isKindOfClass: [BKGroup class]]) {
      parent = (BKGroup *) item;
    }
    if (parent) {
      BKBookmark *bk = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.unknown.com"]];
      [bk setTitle: @"New Bookmark"];
      [bookmarkStore addRecord: bk];
      [parent addItem: bk];
      [outlineView reloadData];
      [outlineView reloadItem: parent reloadChildren: YES];
    }
  }
#endif
}

- (void) removeBookmark: (id) sender
{
}

/** Delegate **/
- (void) tableViewSelectionDidChange: (NSNotification *) not
{
  if ([not object] == tableView) {
    int selectedGroup = [tableView selectedRow];
    if (selectedGroup == 0) {
      [[bookmarkView outlineView] reloadData];
    }
  }
}

/** Data source **/
- (int) numberOfRowsInTableView: (NSTableView *) tv
{
  return 1;
}

- (id) tableView: (NSTableView *) tv 
       objectValueForTableColumn: (NSTableColumn *) tc 
       row: (int) rowIndex
{
  return @"All";
}

#if 0
- (void) tableView: (NSTableView *) tv
         setObjectValue: (id) object
         forTableColumn: (NSTableColumn *) tc
         row: (int) rowIndex
{
}
#endif

@end
