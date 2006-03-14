/* -*-objc-*- All Rights reserved */

#import <AppKit/AppKit.h>
#import "FeedList.h"

#import <RSSKit/RSSKit.h>

@interface FilterManager : NSObject
{
  id searchTextField;
  id showOnlySelectedFeeds;
}

+ (id) filterManager;

- (id) init;
- (void) refilter: (id)sender;

- (BOOL) allowsArticle: (RSSArticle*) anArticle;
- (BOOL) allowsFeed: (RSSFeed*) aFeed;

@end
