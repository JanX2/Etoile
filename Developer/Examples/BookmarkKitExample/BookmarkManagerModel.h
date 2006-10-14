#import <AppKit/AppKit.h>

@class BKBookmarkStore;
@class BKTableView;
@class BKOutlineView;

@interface BookmarkManagerModel: NSObject
{
  BKBookmarkStore *bookmarkStore;
  NSMutableArray *topLevelGroups; 
  NSMutableArray *topLevelItems;
  int selectedGroup;

  BKTableView *tableView;
  BKOutlineView *outlineView;
}

- (void) setBookmarkStore: (BKBookmarkStore *) store;
- (BKBookmarkStore *) bookmarkStore;

- (void) setTableView: (BKTableView *) tableView; // not retained
- (void) setOutlineView : (BKOutlineView *) outlineView; // not retained
@end
