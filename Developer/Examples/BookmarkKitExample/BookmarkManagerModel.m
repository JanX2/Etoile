#import <AppKit/AppKit.h>
#import "BookmarkManagerModel.h"
#import <BookmarkKit/BookmarkKit.h>
#import "BKTableView.h"
#import "BKOutlineView.h"

@implementation BookmarkManagerModel

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
  /* cache top level items */
  [topLevelItems removeAllObjects];
  records = [bookmarkStore items];
  count = [records count];
  BKBookmark *bk;
  for (i = 0; i < count; i++) {
    bk = [records objectAtIndex: i];
    if ([bk isTopLevel] == BKTopLevel) {
      NSLog(@"top bk %@", bk);
      [topLevelItems addObject: bk];
    }
  }
}

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
  topLevelItems = [[NSMutableArray alloc] init];
  selectedGroup = -1; /* Top level */

  return self;
}

- (void) dealloc
{
  DESTROY(topLevelGroups);
  DESTROY(topLevelItems);
  [super dealloc];
}

/** Delegate **/
- (void) tableViewSelectionDidChange: (NSNotification *) not
{
  NSLog(@"tableViewSelectionDidChange");
  BKTableView *tv = [not object];
  int selectedRow = [tv selectedRow];
  selectedGroup = selectedRow - (([topLevelItems count] > 0) ? 1 : 0);
  NSLog(@"selectedGroup %d", selectedGroup);
  [outlineView reloadData];
}

/** Data source **/
- (int) numberOfRowsInTableView: (NSTableView *) tv
{
  // including top level items
  int offset = ([topLevelItems count] > 0) ? 1 : 0;
  return [topLevelGroups count] + offset; 
}

- (id) tableView: (NSTableView *) tv 
       objectValueForTableColumn: (NSTableColumn *) tc 
       row: (int) rowIndex
{
  int index = ([topLevelItems count] > 0 ? rowIndex-1 : rowIndex);

  if (index > -1) {
    return [[topLevelGroups objectAtIndex: index] valueForProperty: [tc identifier]];
  } else {
    return @"Top level items";
  }
}

- (int) outlineView: (NSOutlineView *) ov 
        numberOfChildrenOfItem: (id) item
{
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
  } else {
    if (item == nil) {
      return [topLevelItems count];
    } 
  }
  return 0;
}

- (BOOL) outlineView: (NSOutlineView *) ov 
         isItemExpandable: (id) item
{
  if ([item isKindOfClass: [BKBookmark class]]) {
    return NO;
  } else if ([item isKindOfClass: [BKGroup class]]) {
    BKGroup *group = (BKGroup *) item;
    return ([[group subgroups] count] + [[group items] count] > 0) ? YES : NO;
  } else {
    // Unknown class
    return NO;
  }
}

- (id) outlineView: (NSOutlineView *) ov 
       child: (int) index ofItem: (id) item
{
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
  } else {
    /* Top level items. Cannot have group */
    return [topLevelItems objectAtIndex: index];
  }
}

- (id) outlineView: (NSOutlineView *) ov
       objectValueForTableColumn: (NSTableColumn *) tc
       byItem:(id)item
{
  return [item valueForProperty: [tc identifier]];
}

@end
