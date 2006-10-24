#import <AppKit/AppKit.h>
#import "BookmarkManagerModel.h"
#import <BookmarkKit/BookmarkKit.h>
#import "BKTableView.h"
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

/* Private 
 * This method decide which group a new bookmark or group should be.
 * Return nil if no group is found.
 */
- (BKGroup *) parentGroupOfSelectedItem
{
  BKOutlineView *ov = [bookmarkView outlineView];
  int selectedRow = [ov selectedRow];
  BKGroup *parent = nil;
  if (selectedRow > -1) {
    id item = [ov itemAtRow: selectedRow];
    if ([item isKindOfClass: [BKGroup class]]) {
      parent = (BKGroup *)item;
    } else if ([item isKindOfClass: [BKBookmark class]]) {
      if ([(BKBookmark *)item isTopLevel] == BKNotTopLevel) {
        parent = [[(BKBookmark *) item parentGroups] objectAtIndex: 0];
      }
    }
  }
  return parent;
}

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
    [bookmarkStore removeBookmark: bk];
  }
  if ([bookmarkStore removeRecord: g] == NO) {
    NSLog(@"Fail to remove %@(%@)", g, [g valueForProperty: kBKGroupNameProperty]);
  }
}
/* End of Private */

- (void) addGroup: (id) sender
{
  BKGroup *group = [[BKGroup alloc] init];
  [group setValue: @"New Group" forProperty: kBKGroupNameProperty];
  [bookmarkStore addRecord: group];

  BKOutlineView *ov = [bookmarkView outlineView];
  BKGroup *parent = nil;
  parent = [self parentGroupOfSelectedItem];
  if (parent) {
    [parent addSubgroup: group];
  } 
  [bookmarkView reloadData];
  if (parent) {
    [ov expandItem: parent];
  }
}

- (void) addBookmark: (id) sender
{
  BKBookmark *bk = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.unknown.com"]];
  [bk setTitle: @"New Bookmark"];
  [bookmarkStore addRecord: bk];

  BKOutlineView *ov = [bookmarkView outlineView];
  BKGroup *parent = nil;
  parent = [self parentGroupOfSelectedItem];
  if (parent) {
    [parent addItem: bk];
  } 
  [bookmarkView reloadData];
  if (parent) {
    [ov expandItem: parent];
  }
}

- (void) deleteItem: (id) sender
{
  BKOutlineView *ov = [bookmarkView outlineView];
  int selectedRow = [ov selectedRow];
  if (selectedRow != NSNotFound) {
    id item = [ov itemAtRow: selectedRow];
    if ([item isKindOfClass: [BKBookmark class]]) {
      [bookmarkStore removeBookmark: (BKBookmark *)item];
    } else if ([item isKindOfClass: [BKGroup class]]) {
      /* Must remove all subgroups and all items */
      [self removeGroupRecursive: (BKGroup *)item];
    }
  }
  [bookmarkView reloadData];
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
