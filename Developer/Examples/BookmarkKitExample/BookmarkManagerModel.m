#import <AppKit/AppKit.h>
#import "BookmarkManagerModel.h"
#import <BookmarkKit/BookmarkKit.h>
#import "BKTableView.h"
#import "BKOutlineView.h"
#import "GNUstep.h"

@implementation BookmarkManagerModel

/** Private **/
- (void) cacheBookmarkStore
{
  /* cache top level groups */
  [topLevelGroups removeAllObjects];
  NSArray *records = [bookmarkStore groups];
  int i, count = [records count];
  BKGroup *group;
  for (i = 0; i < count; i++) {
    group = [records objectAtIndex: i];
    if ([group isTopLevel] == BKTopLevel) {
      [topLevelGroups addObject: group];
    }
  }
  /* Ignore top level items now because it creates inconsistency.
   * In another word, better not to have any item which has no parent group.
   */
}

- (NSView *) activeView
{
  if ([tableView active])
    return tableView;
  else if ([outlineView active])
    return outlineView;
  else
    return nil;
}

- (BKGroup *) selectedGroupInTableView
{
  if (selectedGroup > -1)
    return [topLevelGroups objectAtIndex: selectedGroup];
  return nil;
}

/** End of private **/

- (void) setBookmarkStore: (BKBookmarkStore *) store
{
  ASSIGN(bookmarkStore, store);
  [self cacheBookmarkStore];
}

- (BKBookmarkStore *) bookmarkStore
{
  return bookmarkStore;
}

- (void) setTableView: (BKTableView *) tv 
{
  // not retained
  tableView = tv;
}

- (void) setOutlineView : (BKOutlineView *) ov
{
  // not retained
  outlineView = ov;
}


- (id) init
{
  self = [super init];

  topLevelGroups = [[NSMutableArray alloc] init];
  selectedGroup = -1;

  return self;
}

- (void) dealloc
{
  DESTROY(topLevelGroups);
  [super dealloc];
}

/** Controller */
- (void) addGroup: (id) sender
{
  NSView *activeView = [self activeView];
  if (activeView == tableView) {
    BKGroup *group = [[BKGroup alloc] init];
    [group setValue: @"New Group" forProperty: kCKGroupNameProperty];
    [bookmarkStore addRecord: group];
    [topLevelGroups addObject: group];
    [tableView reloadData];
    int index = [topLevelGroups indexOfObject: group];
    [tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
           byExtendingSelection: NO];
    [tableView editColumn: 0 row: index withEvent: nil select: YES];
  } else if (activeView == outlineView) { 
    BKOutlineView *ov = (BKOutlineView *) activeView;
    int selectedRow = [ov selectedRow];
    BKGroup *group = [[BKGroup alloc] init];
    [group setValue: @"New Group" forProperty: kCKGroupNameProperty];
    BKGroup *parent;
    if (selectedRow == NSNotFound) {
      parent = [self selectedGroupInTableView];
    } else {
      id item = [ov itemAtRow: selectedRow];
      if ([item isKindOfClass: [BKGroup class]]) {
        parent = (BKGroup *)item;
      } else {
        parent = [self selectedGroupInTableView];
      }
    }
    if (parent) {
      [bookmarkStore addRecord: group];
      [parent addSubgroup: group];
      [outlineView reloadData];
    }
  }
}

- (void) removeGroup: (id) sender
{
  NSView *activeView = [self activeView];
  if (activeView == tableView) {
  } else if (activeView == outlineView) {
  }
}

- (void) addBookmark: (id) sender
{
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
}

- (void) removeBookmark: (id) sender
{
  NSView *activeView = [self activeView];
  if (activeView == tableView) {
  } else if (activeView == outlineView) {
  }
}

/** Delegate **/
- (void) tableViewSelectionDidChange: (NSNotification *) not
{
  if ([not object] == tableView) {
    selectedGroup= [tableView selectedRow];
    [outlineView reloadData];
  }
}

/** Data source **/
- (int) numberOfRowsInTableView: (NSTableView *) tv
{
  if (tv == tableView) {
    return [topLevelGroups count]; 
  }
  return 0;
}

- (id) tableView: (NSTableView *) tv 
       objectValueForTableColumn: (NSTableColumn *) tc 
       row: (int) rowIndex
{
  if (tv == tableView) {
    return [[topLevelGroups objectAtIndex: rowIndex] valueForProperty: [tc identifier]];
  }
  return nil;
}

- (void) tableView: (NSTableView *) tv
         setObjectValue: (id) object
         forTableColumn: (NSTableColumn *) tc
         row: (int) rowIndex
{
  if (tv == tableView) {
    BKGroup *group = [topLevelGroups objectAtIndex: rowIndex];
    if (group) {
      [group setValue: object forProperty: kCKGroupNameProperty];
    }
  }
}

- (int) outlineView: (NSOutlineView *) ov 
        numberOfChildrenOfItem: (id) item
{
  if (ov != outlineView) 
    return 0;

  if ([item isKindOfClass: [BKBookmark class]])
    return 0;

  if (selectedGroup > -1 ) {
    BKGroup *group = nil;
    if (item == nil) {
      group = [topLevelGroups objectAtIndex: selectedGroup];
    } else {
      group = (BKGroup *)item;
    }
    return [[group subgroups] count] + [[group items] count];
  } 
  return 0;
}

- (BOOL) outlineView: (NSOutlineView *) ov 
         isItemExpandable: (id) item
{
  if (ov != outlineView)
    return NO;

  if ([item isKindOfClass: [BKBookmark class]]) {
    return NO;
  } else if ([item isKindOfClass: [BKGroup class]]) {
    BKGroup *group = (BKGroup *) item;
    return ([[group subgroups] count] + [[group items] count] > 0) ? YES : NO;
  } 
  return NO;
}

- (id) outlineView: (NSOutlineView *) ov 
       child: (int) index ofItem: (id) item
{
  if (ov != outlineView)
    return nil;

  if (selectedGroup > -1 ) {
    BKGroup *group;
    int gcount;
    if (item == nil) {
      group = [topLevelGroups objectAtIndex: selectedGroup];
    } else {
      group = (BKGroup *)item;
    }
    gcount = [[group subgroups] count];
    if (index < gcount) {
      /* Group first */
      return [[group subgroups] objectAtIndex: index];
    } else {
      return [[group items] objectAtIndex: index - gcount];
    }
  }
  return nil;
}

- (id) outlineView: (NSOutlineView *) ov
       objectValueForTableColumn: (NSTableColumn *) tc
       byItem:(id)item
{
  if (ov != outlineView)
    return nil;

  if ([item isKindOfClass: [BKBookmark class]]) {
    return [item valueForProperty: [tc identifier]];
  } else if ([item isKindOfClass: [BKGroup class]]) {
    if ([[ov tableColumns] indexOfObject: tc] == 0)
      return [item valueForProperty: kCKGroupNameProperty];
  }
  return nil;
}

@end
