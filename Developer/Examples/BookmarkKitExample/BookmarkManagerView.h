#import <AppKit/AppKit.h>
#import "BKTableView.h"
#import "BKOutlineView.h"
#import "BookmarkManagerModel.h"

@interface BookmarkManagerView : NSView
{
  BKTableView *tableView;
  BKOutlineView *outlineView;
  NSView *contentView;
  NSScrollView *tableScrollView, *outlineScrollView;
  NSSplitView *leftSplitView, *rightSplitView;

  BookmarkManagerModel *model;

  BOOL isEditable;
  NSMutableArray *displayProperties;
}

- (void) reloadData;
- (BookmarkManagerModel *) model;

/* Make bookmark editable (NO by default)*/
- (void) setEditable: (BOOL) editable;
- (BOOL) isEditable;

/* Properties to displayed in outline view.
 * Each property corresponds to a table column. */
- (void) setDisplayProperties: (NSArray *) keys; // array of property keys
- (NSArray *) diplayProperties;

/* Accessories */
- (BKTableView *) tableView;
- (void) setTableView: (BKTableView *) view;
- (BKOutlineView *) outlineView;
- (void) setOutlineView: (BKOutlineView *) view;
- (NSView *) contentView;
- (void) setContentView: (NSView *) view;
- (NSSplitView *) leftSplitView;
- (NSSplitView *) rightSplitView;
@end
