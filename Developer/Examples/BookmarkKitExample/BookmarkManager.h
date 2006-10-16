#include <AppKit/AppKit.h>

@class BKBookmarkStore;
@class BookmarkManagerModel;
@class BookmarkManagerView;

@interface BookmarkManager : NSObject
{
  BookmarkManagerView *bookmarkManagerView;
  NSWindow *window;

  BKBookmarkStore *bookmarkStore;
  BookmarkManagerModel *model;
}
- (void) addGroup: (id)sender;
- (void) addBookmark: (id)sender;
- (void) deleteItem: (id)sender;
- (void) openBookmark: (id)sender;
- (void) saveBookmark: (id)sender;
@end

