#import <AppKit/AppKit.h>

@class BKBookmarkStore;
@class BKTableView;
@class BKOutlineView;

@interface BookmarkManagerModel: NSObject
{
  BKBookmarkStore *bookmarkStore;
  NSMutableArray *topLevelGroups; 
  int selectedGroup;

  BKTableView *tableView;
  BKOutlineView *outlineView;
}

/* Model */
- (void) setBookmarkStore: (BKBookmarkStore *) store;
- (BKBookmarkStore *) bookmarkStore;

/* Controller */
- (void) setTableView: (BKTableView *) tableView; // not retained
- (void) setOutlineView : (BKOutlineView *) outlineView; // not retained

- (void) addGroup: (id) sender;
- (void) removeGroup: (id) sender;
- (void) addBookmark: (id) sender;
- (void) removeBookmark: (id) sender;
@end
