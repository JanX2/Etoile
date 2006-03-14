/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MainTableDelegate.h"

#import "ArticleViewing.h"
#import "RSSReaderArticle.h"

@implementation MainTableDelegate

// must be efficient!
-(int) numberOfRowsInTableView: (NSTableView*)aTableView
{
  return [[getFeedList() articleList] count];
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
  RSSArticle* article =
    [[getFeedList() articleList] objectAtIndex: rowIndex];
  
  [article viewArticle];
  
  return YES;
}

// must be efficient!
- (id)              tableView: (NSTableView*) aTableView
    objectValueForTableColumn: (NSTableColumn*) aTableColumn
                          row: (int) rowIndex
{
  id tableIdentifier;
  
  tableIdentifier = [aTableColumn identifier];
  
  if ([tableIdentifier isEqual: @"feedCol"])
    {
      RSSArticle* article =
	[[getFeedList() articleList] objectAtIndex: rowIndex];
      return AUTORELEASE(RETAIN([[article feed] feedName]));
    }
  else if ([tableIdentifier isEqual: @"headlineCol"])
    {
      RSSArticle* article =
	[[getFeedList() articleList] objectAtIndex: rowIndex];
      
      return AUTORELEASE(RETAIN([article headline]));
    }
  else if ([tableIdentifier isEqual: @"dateCol"])
    {
      RSSArticle* article =
	[[getFeedList() articleList] objectAtIndex: rowIndex];
      return AUTORELEASE(RETAIN([[article date] description]));
    }
  else
    {
      NSLog(@"ERROR. I don't know the table column \'%@\'",
	    [tableIdentifier description]);
      
      return @"ERR";
    }
}


// for bold text highlighting...
- (void) tableView: (NSTableView*) tableView
   willDisplayCell: (NSCell*) cell
    forTableColumn: (NSTableColumn*) aTableColumn
	       row: (int) rowIndex
{
  RSSArticle* article =
    [[getFeedList() articleList] objectAtIndex: rowIndex];
  
  if ([article isSubclassedArticle] &&
      [((RSSReaderArticle*)article) isRead] == NO)
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
