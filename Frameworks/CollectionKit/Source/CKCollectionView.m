#import <AppKit/AppKit.h>
#import <CollectionKit/CKCollection.h>
#import <CollectionKit/CKItem.h>
#import <CollectionKit/CKGroup.h>
#import <CollectionKit/CKSearchElement.h>
#import <CollectionKit/CKCollectionView.h>
#import "GNUstep.h"

@implementation CKCollectionView
/** Private **/
- (void) handleCollectionChanged: (NSNotification *) not
{
  // Do nothing
}

- (void) buildInternalCache
{
  [internalCache removeAllObjects];
  if (root == nil) {
    [internalCache setArray: [collection items]];
  } else if ([root isKindOfClass: [CKGroup class]]) {
    CKGroup *group = (CKGroup *) root;
    [internalCache addObjectsFromArray: [group items]];
  } else if ([root isKindOfClass: [NSArray class]]) {
    NSEnumerator *e = [(NSArray *) root objectEnumerator];
    CKGroup *group;
    while ((group = [e nextObject])) {
      [internalCache addObjectsFromArray: [collection itemsUnderGroup: group]];
    }
  }
}

/** End of private **/

- (id) initWithFrame: (NSRect) frame
{ 
  self = [super initWithFrame: frame];

  displaySubgroup = NO;
  displayItemsInSubgroup = NO;

  internalCache = [[NSMutableArray alloc] init];

  NSTableColumn *tvc = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: kCKUIDProperty];
  [[tvc headerCell] setStringValue: _(kCKUIDProperty)];
  [tvc setWidth: 200];
  [tvc setMinWidth: 100];

  NSRect rect = frame;
  tableScrollView = [[NSScrollView alloc] initWithFrame: rect];
  [tableScrollView setBorderType: NSBezelBorder];
  [tableScrollView setHasVerticalScroller: YES];
  [tableScrollView setHasHorizontalScroller: YES];
  [tableScrollView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

  rect.size = [tableScrollView contentSize];
  tableView = [[CKTableView alloc] initWithFrame: rect];
  [tableView setDataSource: self];
  [tableView addTableColumn: tvc];
  [tableView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [tableScrollView setDocumentView: tableView];
  [self addSubview: tableScrollView];

  [tvc sizeToFit];
  [tvc setResizable: YES];
  [tableView setAutoresizesAllColumnsToFit: YES];
  [tableView sizeLastColumnToFit];

  RELEASE(tableScrollView);
  RELEASE(tableView);
  RELEASE(tvc);

  /* Listen to collection change */
  [[NSNotificationCenter defaultCenter] addObserver: self
                          selector: @selector(handleCollectionChanged:)
                          name: CKCollectionChangedNotification
                          object: nil];

  return self;
}

- (void) dealloc
{
  DESTROY(collection);
  DESTROY(root);
  DESTROY(displayProperties);
  DESTROY(displaySubgroupProperty);
  DESTROY(internalCache);
  [super dealloc];
}

- (id) itemAtIndex: (int) index
{
  return [internalCache objectAtIndex: index];
#if 0
  if (root == nil) {
    return [[collection items] objectAtIndex: index];
  } else if ([root isKindOfClass: [CKGroup class]]) {
    CKGroup *group = (CKGroup *)root;
    if (displaySubgroup == YES) {
      int gcount = [[group subgroups] count];
      if (index< gcount) {
        return [[group subgroups] objectAtIndex: index];
      } else {
        return [[group items] objectAtIndex: index-gcount];
      }
    } else {
      return [[group items] objectAtIndex: index];
    }
  } else if ([root isKindOfClass: [CKSearchElement class]]) {
    /* No implementation */
    return nil;
  }
  return nil;
#endif
}

/* Data source */
- (int) numberOfRowsInTableView: (NSTableView *) tv
{
  if ((collection == nil) || (tv != tableView))
  {
    return 0;
  }

  return [internalCache count];
#if 0
  if (root == nil) {
    return [[collection items] count];
  } else if ([root isKindOfClass: [CKGroup class]]) {
    CKGroup *group = (CKGroup *)root;
    if (displaySubgroup == YES) {
      return ([[group items] count] +  [[group subgroups] count]);
    } else {
      return [[group items] count];
    }
  } else if ([root isKindOfClass: [CKSearchElement class]]) {
    /* No implementation */
    return 0;
  }
  return 0;
#endif
}

- (id) tableView: (NSTableView *) tv
       objectValueForTableColumn: (NSTableColumn *) tc
       row: (int) rowIndex
{
  if ((collection == nil) || (tv != tableView))
  {
    return nil;
  }
  
  id item = [self itemAtIndex: rowIndex];
  if ([item isKindOfClass: [CKItem class]]) {
    return [(CKItem *) item valueForProperty: [tc identifier]];
  } else if ([item isKindOfClass: [CKGroup class]]) {
    return [(CKGroup *) item valueForProperty: displaySubgroupProperty];
  }
  return nil;
}

/* Accessories */
- (void) setDisplayProperties: (NSArray *) keys
{
  // array of property keys
  ASSIGNCOPY(displayProperties, keys);
  /* remove extra */
  while ([[tableView tableColumns] count] > [displayProperties count]) {
      [tableView removeTableColumn: [[tableView tableColumns] lastObject]];
  }
  /* reset identifier and add extra */
  int i;
  NSTableColumn *tc;
  NSString *key;
  for (i = 0; i < [displayProperties count]; i++) {
    NSArray *tcs = [tableView tableColumns];
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
      [tableView addTableColumn: tc];
      RELEASE(tc);
    }
  }
  [tableView sizeToFit];
  [tableView sizeLastColumnToFit];
}

- (NSArray *) displayProperties
{
  return displayProperties;
}

- (void) reloadData
{
  [tableView reloadData];
}

- (void) setCollection: (CKCollection *) s
{
  ASSIGN(collection, s);
  [self buildInternalCache];
}

- (CKCollection *) collection
{
  return collection;
}

- (CKTableView *) tableView
{
  return tableView;
}

- (void) setRoot: (id) r
{
  ASSIGN(root, r);
  [self buildInternalCache];
}

- (id) root
{
  return root;
}

- (void) setSearchElement: (CKSearchElement *) element
{
  ASSIGN(searchElement, element);
  [self buildInternalCache];
}

- (CKSearchElement *) searchElement
{
  return searchElement;
}

- (void) setDisplaySubgroup: (BOOL) b
{
  displaySubgroup = b;
  [self buildInternalCache];
}

- (BOOL) isDisplaySubgroup
{
  return displaySubgroup;
}

- (void) setDisplayItemsInSubgroup: (BOOL) b
{
  displayItemsInSubgroup = b;
  [self buildInternalCache];
}

- (BOOL) isDisplayItemsInSubgroup
{
  return displayItemsInSubgroup;
}

- (void) setDisplaySubgroupProperty: (id) p
{
  ASSIGNCOPY(displaySubgroupProperty, p);
}

- (id) displaySubgroupProperty
{
  return displaySubgroupProperty;
}

@end

@implementation CKTableView
@end

