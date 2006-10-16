#import <AppKit/AppKit.h>
#import "BookmarkManagerView.h"
#import <CollectionKit/CollectionKit.h>
#import "GNUstep.h"

@implementation BookmarkManagerView

- (void) reloadData
{
  [tableView reloadData];
  [[bookmarkView outlineView] reloadData];
}

- (BookmarkManagerModel *) model
{
  return model;
}

- (id) initWithFrame: (NSRect) frame
{
  NSRect rect;
  self = [super initWithFrame: frame];

  model = [[BookmarkManagerModel alloc] init];

  splitView = [[NSSplitView alloc] initWithFrame: [self bounds]];
  [splitView setVertical: YES];
  [splitView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

  NSTableColumn *tvc = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: kBKGroupNameProperty];
  [[tvc headerCell] setStringValue: _(kBKGroupNameProperty)];
  [tvc setWidth: 300];
  [tvc setMinWidth: 100];

  rect = NSMakeRect(0, 0, 150, frame.size.height);
  tableScrollView = [[NSScrollView alloc] initWithFrame: rect];
  [tableScrollView setBorderType: NSBezelBorder];
  [tableScrollView setHasVerticalScroller: YES];
  [tableScrollView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

  rect.size = [tableScrollView contentSize];
  tableView = [[BKTableView alloc] initWithFrame: rect];
  [tableView setDataSource: model];
  [tableView setDelegate: model];
  [tableView addTableColumn: tvc];
  [tableView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [tableScrollView setDocumentView: tableView];
  [splitView addSubview: tableScrollView];

  rect = NSMakeRect(0, 0, frame.size.width-150, frame.size.height);
  bookmarkView = [[BKBookmarkView alloc] initWithFrame: rect];
  [splitView addSubview: bookmarkView];

  [tvc sizeToFit];
  [tvc setResizable: YES];
  [tableView setAutoresizesAllColumnsToFit: YES];
  [tableView sizeLastColumnToFit];

  RELEASE(tableScrollView);
  RELEASE(tableView);
  RELEASE(tvc);
  RELEASE(bookmarkView);

  [self addSubview: splitView];
  RELEASE(splitView);

  [self setEditable: YES];
  [model setTableView: tableView];
  [model setBookmarkView: bookmarkView];
  return self;
}

- (void) dealloc
{
  DESTROY(model);
  [super dealloc];
}

- (void) setEditable: (BOOL) editable
{
  isEditable = editable;

  NSArray *array = [tableView tableColumns];
  int i, count = [array count];
  for (i = 0; i < count; i++) {
    [(NSTableColumn *)[array objectAtIndex: i] setEditable: isEditable];
  }

  array = [[bookmarkView outlineView] tableColumns];
  count = [array count];
  for (i = 0; i < count; i++) {
    [(NSTableColumn *)[array objectAtIndex: i] setEditable: isEditable];
  }
}

- (BOOL) isEditable
{
  return isEditable;
}

- (BKTableView *) tableView
{
  return tableView;
}

- (void) setTableView: (BKTableView *) view
{
  ASSIGN(tableView, view);
}

- (BKBookmarkView *) bookmarkView
{
  return bookmarkView;
}

- (void) setBookmarkView: (BKBookmarkView *) view
{
  ASSIGN(bookmarkView, view);
}

- (NSSplitView *) splitView
{
  return splitView;
}

@end
