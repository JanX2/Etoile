/* -*-objc-*- All Rights reserved */

#import <AppKit/AppKit.h>
#import "FilterManager.h"
#import "FeedSelection.h"

id filterManagerSingleton = nil;

@implementation FilterManager

+ (id) filterManager
{
  if (filterManagerSingleton==nil)
    {
      filterManagerSingleton = [[FilterManager alloc] init];
    }
  
  return filterManagerSingleton;
}

- (id) init
{
  [super init];
  filterManagerSingleton = self;
  return self;
}

- (void) refilter: (id)sender
{
  [getFeedList() setArticleListDirty: YES];
  [getMainController() refreshMainTable];
}

- (BOOL) allowsArticle: (RSSArticle*) anArticle
{
  NSString* searchString;
  
  // Fetch search string
  searchString = [searchTextField stringValue];
  
  // Check if main search string is empty.
  if ([searchString length] == 0)
    return YES;
  
  // Check if it matches headline.
  if ([[anArticle headline]
	rangeOfString: searchString
	options: NSCaseInsensitiveSearch].location != NSNotFound)
    {
      return YES;
    }
  
  if ([[anArticle description]
	rangeOfString: searchString
	options: NSCaseInsensitiveSearch].location != NSNotFound)
    {
      return YES;
    }
  
  return NO;
}

- (BOOL) allowsFeed: (RSSFeed*) aFeed
{
  if ([showOnlySelectedFeeds state] == NSOffState ||
      [RSSFeed selectedFeed] == nil)
    return YES;
  
  return [aFeed isSelected];
}

@end
