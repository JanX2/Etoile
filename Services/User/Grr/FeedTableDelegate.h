/* -*-objc-mode-*-
 * All Rights reserved
 */

#import <AppKit/AppKit.h>
#import "FeedList.h"

@interface FeedTableDelegate : NSObject
{
}



// must be efficient!
-(int) numberOfRowsInTableView: (NSTableView*)aTableView;


// implementation is optional
/*
-(BOOL) tableView: (NSTableView*) tableView
       acceptDrop: (id <NSDraggingInfo>) info
              row: (int) row
    dropOperation: (NSTableViewDropOperation) operation;
*/


// is executed when something is clicked
-(BOOL) tableView: (NSTableView*) aTableView
  shouldSelectRow: (int) rowIndex;

// must be efficient!
- (id)              tableView: (NSTableView*) aTableView
    objectValueForTableColumn: (NSTableColumn*) aTableColumn
                          row: (int) rowIndex;


- (void) tableView: (NSTableView*) tableView
    setObjectValue: (id) anObject
    forTableColumn: (NSTableColumn*) aTableColumn
               row: (int) rowIndex;

// changes boldness and color
- (void) tableView: (NSTableView*) tableView
   willDisplayCell: (NSCell*) cell
    forTableColumn: (NSTableColumn*) aTableColumn
	       row: (int) rowIndex;

@end
