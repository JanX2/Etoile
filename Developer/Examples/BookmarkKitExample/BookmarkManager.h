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
- (void) addBookmark: (id)sender;
- (void) addGroup: (id)sender;
- (void) removeGroup: (id)sender;
- (void) openBookmark: (id)sender;
- (void) removeBookmark: (id)sender;
- (void) saveBookmark: (id)sender;
@end

