#import <AppKit/AppKit.h>
#import <BookmarkKit/BKBookmarkStore.h>
#import <BookmarkKit/BKGroup.h>

@interface BKOutlineView: NSOutlineView
@end

@interface BKBookmarkView: NSView
{
  BKOutlineView *outlineView;
  NSScrollView *outlineScrollView;

  BKBookmarkStore *store;
  BKGroup *rootGroup;
  NSArray *displayProperties;

  NSMutableArray *topLevelGroups;
  NSMutableArray *topLevelItems;
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
