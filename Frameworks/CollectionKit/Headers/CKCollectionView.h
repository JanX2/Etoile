#import <AppKit/AppKit.h>
#import <CollectionKit/CKCollection.h>
#import <CollectionKit/CKGroup.h>

/** 
 * CKCollectionView implement a table view with a scroll view
 * to display a CKCollection, which serves as data source.
 * The delegate of table view can be used to control its behavior.
 * 
 * If root is nil, display all items in collection.
 * If root is a CKGroup, display all items in that group.
 * If root is CKSearchEleemtn, display the search result.
 */

@interface CKTableView : NSTableView
@end

@interface CKCollectionView: NSView
{
  CKTableView *tableView;
  NSScrollView *tableScrollView;

  CKCollection *collection;
  id root;
  NSArray *displayProperties;
  BOOL displaySubgroup;
  BOOL displayItemsInSubgroup;
  id displaySubgroupProperty;
  CKSearchElement *searchElement;

  /* Internal cache for items */
  NSMutableArray *internalCache;
  BOOL isEditing;

  /* Sorting */
  BOOL reverseSorting;
  NSString *sortingProperty;
}

- (void) setCollection: (CKCollection *) collection;
- (CKCollection *) collection;
- (CKTableView *) tableView; // expose table view for easy access

/* These are the possible options for root:
 * nil: display all items.
 * CKGroup: display all items in the given group.
 * NSArray of CKGroups: display all items in the given groups.
 */
- (void) setRoot: (id) root;
- (id) root;

/* Display items matching search element.
 * If nil, display all.
 */
- (void) setSearchElement: (CKSearchElement *) element;
- (CKSearchElement *) searchElement;

/* Item at index of table view. 
 * Could be CKGroup if subgroup is allowed for display
 */
- (id) itemAtIndex: (int) row; 
- (int) numberOfItems; /* the ones display on table view, not in collection */

/* Properties to displayed in table view.
 * Each property corresponds to a table column. */
- (void) setDisplayProperties: (NSArray *) keys; // array of property keys
- (NSArray *) displayProperties;

/* Display only CKItem in table view ? Default value is NO.
 * It is only useful when root is CKGroup */
- (void) setDisplaySubgroup: (BOOL) b;
- (BOOL) isDisplaySubgroup;

/* Display items under subgroup.
 * If YES, isDisplaySubgroup is ignored.
 */
- (void) setDisplayItemsInSubgroup: (BOOL) b;
- (BOOL) isDisplayItemsInSubgroup;

/* Since CKGroup have different properties than CKItem.
 * Select which property to display */
- (void) setDisplaySubgroupProperty: (id) property;
- (id) displaySubgroupProperty;

/* Sort item in table view based on property.
 * It use -compare:
 */
- (void) sortWithProperty: (NSString *) property reverse: (BOOL) reverse;
/* If this property is set, the table view is always sorted.
 * Set nil to remove sorting.
 */
- (void) setSortingProperty: (NSString *) property reverse: (BOOL) reverse;

/* Recreate cache. Use when collection is changed */
- (void) reloadData;

/* This delay rebuild cache until -endEditing is called.
 * It is suitable when large number of records is changed.  */
- (void) beginEditing;
- (void) endEditing;

@end
