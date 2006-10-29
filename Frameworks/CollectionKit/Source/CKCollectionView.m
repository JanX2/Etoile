#import <AppKit/AppKit.h>
#import <CollectionKit/CKCollection.h>
#import <CollectionKit/CKItem.h>
#import <CollectionKit/CKGroup.h>
#import <CollectionKit/CKSearchElement.h>
#import <CollectionKit/CKCollectionView.h>
#import "GNUstep.h"

NSComparisonResult sortingWithProperty(id record1, id record2, void *context)
{
  NSString *property = (NSString *) context;
  id value1 = [(CKRecord *) record1 valueForProperty: property];
  id value2 = [(CKRecord *) record2 valueForProperty: property];
  return [value1 compare: value2];
}

NSComparisonResult reverseSortingWithProperty(id record1, id record2, void *context)
{
  NSComparisonResult result = sortingWithProperty(record1, record2, context);
  switch(result) {
    case NSOrderedAscending:
      return NSOrderedDescending;
    case NSOrderedDescending:
      return NSOrderedAscending;
    default:
      return NSOrderedSame;
  }
}

@implementation CKCollectionView
/** Private **/
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
  } else {
    NSLog(@"Error: unknown root %@", root);
  }

  if (searchElement != nil) {
    /* Remove unmatched item */
    int i;
    for (i = 0; i < [internalCache count]; i++) {
      CKRecord *record = [internalCache objectAtIndex: i];
      if ([searchElement matchesRecord: record] == NO) {
        [internalCache removeObjectAtIndex: i];
        i--;
      }
    }
  }
 
  if (sortingProperty) {
    /* Always keep sorted */
    [self sortWithProperty: sortingProperty reverse: reverseSorting];
  }
}

- (void) handleCollectionChanged: (NSNotification *) not
{
  [self buildInternalCache];
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
  DESTROY(sortingProperty);
  [super dealloc];
}

- (id) itemAtIndex: (int) index
{
  return [internalCache objectAtIndex: index];
}

- (int) numberOfItems
{
  return [internalCache count];
}

/* Data source */
- (int) numberOfRowsInTableView: (NSTableView *) tv
{
  if ((collection == nil) || (tv != tableView))
  {
    return 0;
  }

  return [internalCache count];
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

- (void) sortWithProperty: (NSString *) property reverse: (BOOL) reverse
{
  if (reverse == NO)
    [internalCache sortUsingFunction: sortingWithProperty 
                             context: property];
  else
    [internalCache sortUsingFunction: reverseSortingWithProperty 
                                    context: property];
}

- (void) setSortingProperty: (NSString *) property reverse: (BOOL) reverse
{
  reverseSorting = reverse;
  ASSIGN(sortingProperty, property);
}

@end

@implementation CKTableView
@end

