#import <AppKit/AppKit.h>
#import "BKTableView.h"
#import "BKBookmarkView.h"
#import "BookmarkManagerModel.h"

@interface BookmarkManagerView : NSView
{
  BKTableView *tableView;
  BKBookmarkView *bookmarkView;;
  NSScrollView *tableScrollView;
  NSSplitView *splitView;

  BookmarkManagerModel *model;

  BOOL isEditable;
}

- (void) reloadData;
- (BookmarkManagerModel *) model;

/* Make bookmark editable (NO by default)*/
- (void) setEditable: (BOOL) editable;
- (BOOL) isEditable;

/* Accessories */
- (BKTableView *) tableView;
- (void) setTableView: (BKTableView *) view;
- (BKBookmarkView *) bookmarkView;
- (void) setBookmarkView: (BKBookmarkView *) view;
- (NSSplitView *) splitView;
@end
