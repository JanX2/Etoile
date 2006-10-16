#import <AppKit/AppKit.h>
#import "BKBookmarkView.h"
#import <CollectionKit/CollectionKit.h>
#import "GNUstep.h"

@implementation BKBookmarkView
/** Private **/
- (void) cacheBookmarkStore
{
  /* cache top level groups */
  [topLevelGroups removeAllObjects];
  NSArray *records = [store groups];
  int i, count = [records count];
  BKGroup *group;
  for (i = 0; i < count; i++) {
    group = [records objectAtIndex: i];
    if ([group isTopLevel] == BKTopLevel) {
      [topLevelGroups addObject: group];
    }
  }
  /* cache top level items */
  [topLevelItems removeAllObjects];
  records = [store items];
  count = [records count];
  BKBookmark *bk;
  for (i = 0; i < count; i++) {
    bk = [records objectAtIndex: i];
    if ([bk isTopLevel] == BKTopLevel) {
      [topLevelItems addObject: bk];
    }
  }
}

- (void) handleCollectionChanged: (NSNotification *) not
{
  // Do nothing
}

/** End of private **/

- (id) initWithFrame: (NSRect) frame
{ 
  self = [super initWithFrame: frame];

  NSTableColumn *ovc = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: kCKUIDProperty];
  [[ovc headerCell] setStringValue: _(kCKUIDProperty)];
  [ovc setWidth: 200];
  [ovc setMinWidth: 100];

  NSRect rect = frame;
  outlineScrollView = [[NSScrollView alloc] initWithFrame: rect];
  [outlineScrollView setBorderType: NSBezelBorder];
  [outlineScrollView setHasVerticalScroller: YES];
  [outlineScrollView setHasHorizontalScroller: YES];
  [outlineScrollView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

  rect.size = [outlineScrollView contentSize];
  outlineView = [[BKOutlineView alloc] initWithFrame: rect];
  [outlineView setDataSource: self];
  [outlineView setDelegate: self];
  [outlineView addTableColumn: ovc];
  [outlineView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [outlineScrollView setDocumentView: outlineView];
  [self addSubview: outlineScrollView];

  [ovc sizeToFit];
  [ovc setResizable: YES];
  [outlineView setAutoresizesAllColumnsToFit: YES];
  [outlineView sizeLastColumnToFit];
  [outlineView setOutlineTableColumn: ovc];

  RELEASE(outlineScrollView);
  RELEASE(outlineView);
  RELEASE(ovc);

  topLevelGroups = [[NSMutableArray alloc] init];
  topLevelItems = [[NSMutableArray alloc] init];

  /* Listen to record change */
  [[NSNotificationCenter defaultCenter] addObserver: self
                          selector: @selector(handleCollectionChanged:)
                          name: CKCollectionChangedNotification
                          object: nil];

  return self;
}

- (void) dealloc
{
  DESTROY(store);
  DESTROY(rootGroup);
  DESTROY(topLevelGroups);
  DESTROY(topLevelItems);
  [super dealloc];
}

/* Controller */

/* Data source */
- (int) outlineView: (NSOutlineView *) ov 
        numberOfChildrenOfItem: (id) item
{
  if ((store == nil) ||
      (ov != outlineView) ||
      ([item isKindOfClass: [BKBookmark class]])) 
  {
    return 0;
  }

  BKGroup *group;
  if (item == nil) {
    if (rootGroup == nil) {
      /* Top level */
      return [topLevelGroups count]+[topLevelItems count];
    } else {
      group = rootGroup;
    }
  } else {
    group = (BKGroup *)item;
  }
  return [[group subgroups] count] + [[group items] count];
}

- (BOOL) outlineView: (NSOutlineView *) ov 
         isItemExpandable: (id) item
{
  if ((store == nil) ||
      (ov != outlineView) ||
      ([item isKindOfClass: [BKBookmark class]])) 
  {
    return NO;
  }

  if ([item isKindOfClass: [BKGroup class]]) {
    BKGroup *group = (BKGroup *) item;
    return ([[group subgroups] count] + [[group items] count] > 0) ? YES : NO;
  } 
  return NO;
}

- (id) outlineView: (NSOutlineView *) ov 
       child: (int) index ofItem: (id) item
{
  if ((store == nil) ||
      (ov != outlineView))
  {
    return nil;
  }

  BKGroup *group;
  int gcount;
  if (item == nil) {
    if (rootGroup == nil) {
      /* Top level */
      gcount = [topLevelGroups count];
      if (index < gcount)
        return [topLevelGroups objectAtIndex: index];
      else 
        return  [topLevelItems objectAtIndex: index - gcount];
    } else {
      group = rootGroup;
    }
  } else {
    group = (BKGroup *)item;
  }
  gcount = [[group subgroups] count];
  if (index < gcount) {
    /* Group first */
    return [[group subgroups] objectAtIndex: index];
  } else {
    return [[group items] objectAtIndex: index - gcount];
  }
}

- (id) outlineView: (NSOutlineView *) ov
       objectValueForTableColumn: (NSTableColumn *) tc
       byItem:(id)item
{
  if ((store == nil) ||
      (ov != outlineView))
  {
    return nil;
  }

  if ([item isKindOfClass: [BKBookmark class]]) {
    return [item valueForProperty: [tc identifier]];
  } else if ([item isKindOfClass: [BKGroup class]]) {
    if ([[ov tableColumns] indexOfObject: tc] == 0)
      return [item valueForProperty: kBKGroupNameProperty];
  }
  return nil;
}

- (void) outlineView: (NSOutlineView *) ov
         setObjectValue: (id) object
         forTableColumn: (NSTableColumn *) tc
         byItem:(id)item
{
  if ((store == nil) ||
      (ov != outlineView))
  {
    return;
  }
  if ([item isKindOfClass: [BKGroup class]]) {
    /* Only allow name change */
    BKGroup *group = (BKGroup *) item;
    [group setValue: object forProperty: kBKGroupNameProperty];
  } else if ([item isKindOfClass: [BKBookmark class]]) {
    BKBookmark *bk = (BKBookmark *) item;
    [bk setValue: object forProperty: [tc identifier]];
  }
}

/* Accessories */
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
      RELEASE(tc);
    }
    if (i == 0) {
      [outlineView setOutlineTableColumn: tc];
    }
  }
  [outlineView sizeToFit];
  [outlineView sizeLastColumnToFit];
}

- (NSArray *) displayProperties
{
  return displayProperties;
}

- (void) reloadData
{
  [self cacheBookmarkStore];
  [outlineView reloadData];
}

- (void) setBookmarkStore: (BKBookmarkStore *) s
{
  ASSIGN(store, s);
  [self cacheBookmarkStore];
}

- (BKBookmarkStore *) bookmarkStore
{
  return store;
}

- (BKOutlineView *) outlineView
{
  return outlineView;
}

- (void) setRootGroup: (BKGroup *) g
{
  ASSIGN(rootGroup, g);
}

- (BKGroup *) rootGroup
{
  return rootGroup;
}
@end

@implementation BKOutlineView
@end

