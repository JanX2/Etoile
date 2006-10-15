#import <AppKit/AppKit.h>
#import "BookmarkManagerView.h"
#import <CollectionKit/CollectionKit.h>
#import "GNUstep.h"

@implementation BookmarkManagerView

- (void) reloadData
{
  [tableView reloadData];
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

  leftSplitView = [[NSSplitView alloc] initWithFrame: [self bounds]];
  [leftSplitView setVertical: YES];
  [leftSplitView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

  NSTableColumn *tvc = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: kCKGroupNameProperty];
  [[tvc headerCell] setStringValue: _(kCKGroupNameProperty)];
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
  [leftSplitView addSubview: tableScrollView];

  NSTableColumn *ovc = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: kCKUIDProperty];
  [[ovc headerCell] setStringValue: _(kCKUIDProperty)];
  [ovc setWidth: 200];
  [ovc setMinWidth: 100];

  rect = NSMakeRect(0, 0, frame.size.width-150, frame.size.height);
  outlineScrollView = [[NSScrollView alloc] initWithFrame: rect];
  [outlineScrollView setBorderType: NSBezelBorder];
  [outlineScrollView setHasVerticalScroller: YES];
  [outlineScrollView setHasHorizontalScroller: YES];
  [outlineScrollView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

  rect.size = [outlineScrollView contentSize];
  outlineView = [[BKOutlineView alloc] initWithFrame: rect];
  [outlineView setDataSource: model];
  [outlineView setDelegate: model];
  [outlineView addTableColumn: ovc];
  [outlineView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [outlineScrollView setDocumentView: outlineView];
  [leftSplitView addSubview: outlineScrollView];

  [tvc sizeToFit];
  [ovc sizeToFit];
  [tvc setResizable: YES];
  [ovc setResizable: YES];
  [tableView setAutoresizesAllColumnsToFit: YES];
  [outlineView setAutoresizesAllColumnsToFit: YES];
  [tableView sizeLastColumnToFit];
  [outlineView sizeLastColumnToFit];

  RELEASE(tableScrollView);
  RELEASE(tableView);
  RELEASE(tvc);
  RELEASE(outlineScrollView);
  RELEASE(outlineView);
  RELEASE(ovc);

  [self addSubview: leftSplitView];
  RELEASE(leftSplitView);

  [self setEditable: NO];
  [model setTableView: tableView];
  [model setOutlineView: outlineView];
  return self;
}

- (void) dealloc
{
  DESTROY(model);
  DESTROY(displayProperties);
  [super dealloc];
}

- (void) setDisplayProperties: (NSArray *) keys
{
  // array of property keys
  ASSIGNCOPY(displayProperties, keys);
  /* remove extra */
  while ([[outlineView tableColumns] count] > [displayProperties count]) {
      [outlineView removeTableColumn: [[outlineView tableColumns] lastObject]];
  }
  /* reset identifier and add extra */
  int i;
  NSTableColumn *tc;
  NSString *key;
  for (i = 0; i < [displayProperties count]; i++) {
    NSArray *tcs = [outlineView tableColumns];
    key = [displayProperties objectAtIndex: i];
    if (i < [tcs count]) {
      tc = [tcs objectAtIndex: i];
      [tc setIdentifier: key];
      [[tc headerCell] setStringValue: _(key)];
    } else {
      /* Create new one */
      tc = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: key];
      [[tc headerCell] setStringValue: _(key)];
      [tc setWidth: 200];
      [tc setMinWidth: 100];
      [tc setResizable: YES];
      [outlineView addTableColumn: tc];
      DESTROY(tc);
    }
  }
  [outlineView sizeToFit];
  [outlineView sizeLastColumnToFit];
}

- (NSArray *) diplayProperties
{
  return displayProperties;
}

- (void) setEditable: (BOOL) editable
{
  isEditable = editable;

  NSArray *array = [tableView tableColumns];
  int i, count = [array count];
  for (i = 0; i < count; i++) {
    [(NSTableColumn *)[array objectAtIndex: i] setEditable: isEditable];
  }

  array = [outlineView tableColumns];
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

- (BKOutlineView *) outlineView
{
  return outlineView;
}

- (void) setOutlineView: (BKOutlineView *) view
{
  ASSIGN(outlineView, view);
}

- (NSView *) contentView
{
  return contentView;
}

- (void) setContentView: (NSView *) view
{
  ASSIGN(contentView, view);
}

- (NSSplitView *) leftSplitView
{
  return leftSplitView;
}

- (NSSplitView *) rightSplitView
{
  return rightSplitView;
}

@end
