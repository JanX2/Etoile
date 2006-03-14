/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "FeedTableDelegate.h"

#import "FeedSelection.h"

@implementation FeedTableDelegate


// must be efficient!
-(int) numberOfRowsInTableView: (NSTableView*)aTableView
{
  return [[getFeedList() feedList] count];
}


// implementation is optional
/*
-(BOOL) tableView: (NSTableView*) tableView
       acceptDrop: (id <NSDraggingInfo>) info
              row: (int) row
    dropOperation: (NSTableViewDropOperation) operation;
*/


// is executed when something is clicked
-(BOOL) tableView: (NSTableView*) aTableView
  shouldSelectRow: (int) rowIndex
{
  [[[getFeedList() feedList] objectAtIndex: rowIndex] select];
  return YES;
}

// must be efficient!
- (id)              tableView: (NSTableView*) aTableView
    objectValueForTableColumn: (NSTableColumn*) aTableColumn
                          row: (int) rowIndex
{
  return [[[getFeedList() feedList] objectAtIndex: rowIndex] feedName];  
}

// changes boldness and color
- (void) tableView: (NSTableView*) tableView
   willDisplayCell: (NSCell*) cell
    forTableColumn: (NSTableColumn*) aTableColumn
	       row: (int) rowIndex
{
  RSSFeed* feed = [[getFeedList() feedList] objectAtIndex: rowIndex];
  
  if ([feed status] == RSSFeedIsFetching)
    {
      [cell setFont: [NSFont boldSystemFontOfSize: [NSFont systemFontSize]]];
    }
  else
    {
      [cell setFont: [NSFont systemFontOfSize: [NSFont systemFontSize]]];
    }
}


- (void) tableView: (NSTableView*) tableView
    setObjectValue: (id) anObject
    forTableColumn: (NSTableColumn*) aTableColumn
               row: (int) rowIndex
{
  return;
}

@end
