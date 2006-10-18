#import <AppKit/AppKit.h>
#import "BKBookmarkView.h"
#import <CollectionKit/CollectionKit.h>
#import "GNUstep.h"

NSString *const BKBookmarkUIDDataType = @"BKBookmarkUIDDataType";

@implementation BKBookmarkView
/** Private **/
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
  [outlineView setIndentationPerLevel: 10];
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

  /* Listen to collection change */
  [[NSNotificationCenter defaultCenter] addObserver: self
                          selector: @selector(handleCollectionChanged:)
                          name: CKCollectionChangedNotification
                          object: nil];
  /* Register drag and drop */
  [outlineView registerForDraggedTypes:
               [NSArray arrayWithObject: BKBookmarkUIDDataType]];

  return self;
}

- (void) dealloc
{
  DESTROY(store);
  DESTROY(rootGroup);
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
      return [[store topLevelRecords] count];
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
      return [[store topLevelRecords] objectAtIndex: index];
    } else {
      group = rootGroup;
    }
  } else {
    group = (BKGroup *)item;
  }
#if 1
  NSArray *a = [group valueForProperty: kCKItemsProperty];
  CKRecord *r = [store recordForUniqueID: [a objectAtIndex: index]];
  return r;
#else
  gcount = [[group subgroups] count];
  if (index < gcount) {
    /* Group first */
    return [[group subgroups] objectAtIndex: index];
  } else {
    return [[group items] objectAtIndex: index - gcount];
  }
#endif
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
    if ([[tc identifier] isEqualToString: kBKBookmarkURLProperty]) {
      /* Handle url */
      [bk setURL: [NSURL URLWithString: object]];
    } else {
      [bk setValue: object forProperty: [tc identifier]];
    }
  }
}

/* Drag and drop */

- (BOOL) outlineView: (NSOutlineView *) ov
         writeItems: (NSArray *) items
         toPasteboard: (NSPasteboard *) pboard
{
  NSMutableArray *array = AUTORELEASE([[NSMutableArray alloc] init]);
  NSEnumerator *e = [items objectEnumerator];
  CKRecord *r;
  while ((r = [e nextObject])) {
    [array addObject: [r uniqueID]];
    [pboard declareTypes: [NSArray arrayWithObject: BKBookmarkUIDDataType] owner: self];
    [pboard setPropertyList: array forType: BKBookmarkUIDDataType];
    return YES;
  }
  return NO;
}

- (NSDragOperation) outlineView: (NSOutlineView *) ov
                    validateDrop: (id <NSDraggingInfo>) info
                    proposedItem: (id) item
                    proposedChildIndex: (int) index
{
  if ([info draggingSource] == outlineView) 
  {
    /* Drag inside outline view. Reorganization */
    if (index == -1) {
      /* On an item */
      if ([item isKindOfClass: [BKBookmark class]]) {
        return NSDragOperationNone;
      }
    }
    return NSDragOperationMove;
  }
  return NSDragOperationNone;
}

- (BOOL) outlineView: (NSOutlineView *) ov 
         acceptDrop: (id <NSDraggingInfo>) info
         item: (id) item childIndex: (int) index
{
  int insertIndex, origIndex;
  NSEnumerator *e;
  NSString *uid;
  CKRecord <BKTopLevel> *r;
  BKGroup *parent;
  if ([info draggingSource] == outlineView) {
    /* Drag inside outline view. */
    NSPasteboard *pboard = [info draggingPasteboard]; 
    NSArray *array = [pboard propertyListForType: BKBookmarkUIDDataType];
    if (item == nil) {
      /* Top level records */
      if (index == -1) {
        /* Open space below all items */
        insertIndex = [[store topLevelRecords] count];
      } else {
        insertIndex = index;
      }
      e = [array objectEnumerator];
      while ((uid = [e nextObject])) {
        /* For any non-top level record. remove from its group
         * and it will become a top level.
         * Then insert it on the right place on top level.
         * For top level record, remove from top level record and insert at
         * right place.
         */
        r = [store recordForUniqueID: uid];
        if ([r isTopLevel] == BKNotTopLevel) {
          parent = [[(BKBookmark *)r parentGroups] objectAtIndex: 0];
          if ([r isKindOfClass: [BKGroup class]]) {
            [parent removeSubgroup: (BKGroup *)r];
          } else if ([r isKindOfClass: [BKBookmark class]]) {
            [parent removeItem: (BKBookmark *)r];
          } 
        }
        RETAIN(r);
        origIndex = [[store topLevelRecords] indexOfObject: r];
        [[store topLevelRecords] removeObjectAtIndex: origIndex];
        if (origIndex < insertIndex) {
          insertIndex--;
        }
        [[store topLevelRecords] insertObject: r atIndex: insertIndex];
        insertIndex++;
        RELEASE(r);
      }
    } else if ([item isKindOfClass: [BKBookmark class]]) { 
      /* Add into bookmark.
       * This shouldn't happen because it is not validated.
       * See -outlineView:validateDrop:proposedItem:proposedChildIndex:
       */
      return NO;
    } else if ([item isKindOfClass: [BKGroup class]]) {
      if (index == -1) {
        /* Add into a group with group collapsed..
         * Remove everything from its parent, then added into it. */
         e = [array objectEnumerator];
         while ((uid = [e nextObject])) {
           r = [store recordForUniqueID: uid];
           if ([r isTopLevel] == BKNotTopLevel) {
             parent = [[(BKBookmark *)r parentGroups] objectAtIndex: 0];
             if ([r isKindOfClass: [BKGroup class]]) {
               [parent removeSubgroup: (BKGroup *)r];
             } else if ([r isKindOfClass: [BKBookmark class]]) {
               [parent removeItem: (BKBookmark *)r];
             }
           }
         }
         e = [array objectEnumerator];
         while ((uid = [e nextObject])) {
           r = [store recordForUniqueID: uid];
           if ([r isKindOfClass: [BKGroup class]]) {
             [(BKGroup *)item addSubgroup: (BKGroup *)r];
           } else if ([r isKindOfClass: [BKBookmark class]]) {
             [(BKGroup *)item addItem: (BKBookmark *)r];
           }
         }
      } else {
        /* Add into a group with group collapsed..
         * Remove everything from its parent, then added into it.
         * Because records can be within the target group,
         * the insertIndex has to be offsets to count for the remove of 
         * records. */
        insertIndex = index;
        NSMutableArray *ma = [NSMutableArray arrayWithArray: [(BKGroup *)item valueForProperty: kCKItemsProperty]];
        e = [array objectEnumerator];
        while ((uid = [e nextObject])) {
          r = [store recordForUniqueID: uid];
          if ([r isTopLevel] == BKNotTopLevel) {
            parent = [[(BKBookmark *)r parentGroups] objectAtIndex: 0];
            if (parent == item) {
              origIndex = [ma indexOfObject: uid];
              if (origIndex < insertIndex) {
                insertIndex--;
              }
              [ma removeObject: uid];
            } else {
              if ([r isKindOfClass: [BKGroup class]]) {
                [parent removeSubgroup: (BKGroup *)r];
              } else if ([r isKindOfClass: [BKBookmark class]]) {
                [parent removeItem: (BKBookmark *)r];
              }
            } 
          } 
          [[store topLevelRecords] removeObject: r];
          [r setTopLevel: BKNotTopLevel];
          [ma insertObject: uid atIndex: insertIndex];;
          insertIndex++;
        }
        [item setValue: ma forProperty: kCKItemsProperty];
      }
    } else {
      return NO;
    }
    [self reloadData];
    return YES;
  }
  return NO;
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
//  [self cacheBookmarkStore];
  [outlineView reloadData];
}

- (void) setBookmarkStore: (BKBookmarkStore *) s
{
  ASSIGN(store, s);
//  [self cacheBookmarkStore];
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

