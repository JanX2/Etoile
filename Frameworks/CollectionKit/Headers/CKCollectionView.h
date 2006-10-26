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
  id displaySubgroupProperty;
}

- (void) setCollection: (CKCollection *) collection;
- (CKCollection *) collection;
- (CKTableView *) tableView; // expose table view for easy access

- (void) setRoot: (id) root;
- (id) root;
/* Item at index of table view. 
 * Could be CKGroup if subgroup is allowed for display
 */
- (id) itemAtIndex: (int) row; 

/* Properties to displayed in outline view.
 * Each property corresponds to a table column. */
- (void) setDisplayProperties: (NSArray *) keys; // array of property keys
- (NSArray *) displayProperties;

/* Display only CKItem in table view ? Default value is NO.
 * It is only useful when root is CKGroup */
- (void) setDisplaySubgroup: (BOOL) b;
- (BOOL) isDisplaySubgroup;
- (void) setDisplaySubgroupProperty: (id) property;
- (id) displaySubgroupProperty;

/* Recreate cache. Use when collection is changed */
- (void) reloadData;

@end
