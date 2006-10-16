#import <AppKit/AppKit.h>

@class BKBookmarkStore;
@class BKTableView;
@class BKBookmarkView;

@interface BookmarkManagerModel: NSObject
{
  BKBookmarkStore *bookmarkStore;

  BKTableView *tableView;
  BKBookmarkView *bookmarkView;
}

/* Model */
- (void) setBookmarkStore: (BKBookmarkStore *) store;
- (BKBookmarkStore *) bookmarkStore;

/* Controller */
- (void) setTableView: (BKTableView *) tableView; // not retained
- (void) setBookmarkView: (BKBookmarkView *) bookmarkView; // not retained

- (void) addGroup: (id) sender;
- (void) addBookmark: (id) sender;
- (void) deleteItem: (id) sender;
@end
