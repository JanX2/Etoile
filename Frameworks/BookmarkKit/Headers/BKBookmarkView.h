#import <AppKit/AppKit.h>
#import <BookmarkKit/BKBookmarkStore.h>
#import <BookmarkKit/BKGroup.h>

/** 
 * BKBookmarkView implement an outline view with a scroll view
 * to display a BKBookmarkStore, which serves as data source.
 * The delegate of outline view can be used to control its behavior.
 */

@interface BKOutlineView: NSOutlineView
@end

@interface BKBookmarkView: NSView
{
  BKOutlineView *outlineView;
  NSScrollView *outlineScrollView;

  BKBookmarkStore *store;
  BKGroup *rootGroup;
  NSArray *displayProperties;
}

- (void) setBookmarkStore: (BKBookmarkStore *) store;
- (BKBookmarkStore *) bookmarkStore;
- (BKOutlineView *) outlineView; // expose outline view for easy access

/* Set the starting group to display bookmarks. 
 * If nil, display the all bookmarks.
 * It must be a BKGroup, not BKBookmakr.Why display a single BKBookmark ?
 */
- (void) setRootGroup: (BKGroup *) root;
- (BKGroup *) rootGroup;

/* Properties to displayed in outline view.
 * Each property corresponds to a table column. */
- (void) setDisplayProperties: (NSArray *) keys; // array of property keys
- (NSArray *) displayProperties;

/* Recreate cache. Use when bookmark store is changed */
- (void) reloadData;

@end
