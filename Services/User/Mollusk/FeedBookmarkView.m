#import "FeedBookmarkView.h"
#import "FeedList.h"
#import "Global.h"

@implementation BKOutlineView (FeedBookmarkView)
- (void) keyDown: (NSEvent *) event
{
  NSString *characters = [event characters];
  if ([characters length]) {
    if ([characters characterAtIndex: 0] == NSRightArrowFunctionKey) {
      [[self window] makeFirstResponder: [self nextKeyView]];
      return;
    }
  } 

  [super keyDown: event];
}

@end

@implementation FeedBookmarkView

/** Private **/
- (int) numberOfUnreadArticlesInFeed: (RSSFeed *) feed
{
  FeedList *feedList = [FeedList feedList];
  CKGroup *group = [feedList articleGroupForURL: [feed feedURL]];
  NSArray *items = [[feedList articleCollection] itemsUnderGroup: group];
  int i, total = 0;
  for (i = 0; i < [items count]; i++) {
    if ([[[items objectAtIndex: i] valueForProperty: kArticleReadProperty] intValue] == 0)
    {
      total++;
    }
  }
  return total;
}

/** End of Private **/

/* Override to put unread articles */
- (id) outlineView: (NSOutlineView *) ov
       objectValueForTableColumn: (NSTableColumn *) tc
       byItem:(id)item
{
  int total = 0;
  FeedList *feedList = [FeedList feedList];
  id object = [super outlineView: ov 
                     objectValueForTableColumn: tc
                     byItem: item];

  if ([item isKindOfClass: [BKBookmark class]]) {
    RSSFeed *feed = [feedList feedForURL: [(BKBookmark *)item URL]];
    total = [self numberOfUnreadArticlesInFeed: feed];
  } else if ([item isKindOfClass: [BKGroup class]]) {
    NSArray *feeds = [[feedList feedStore] itemsUnderGroup: (BKGroup *) item];
    int i;
    for (i = 0; i < [feeds count]; i++) {
      RSSFeed *feed = [feedList feedForURL: [[feeds objectAtIndex: i] URL]];
      total += [self numberOfUnreadArticlesInFeed: feed];
    }
  } 

  if (([object isKindOfClass: [NSString class]] == YES) && (total > 0)) 
  {
    object = [object stringByAppendingFormat: @" (%d)", total];
  }

  return object;
}

@end

