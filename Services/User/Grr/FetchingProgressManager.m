#import <RSSKit/RSSKit.h>
#import "FetchingProgressManager.h"
#import "RSSReaderFeed.h"
#import "FeedList.h"
#import "GNUstep.h"
#import "Global.h"

static FetchingProgressManager* instance;

@implementation FetchingProgressManager

+ (FetchingProgressManager *) defaultManager
{
  if (instance == nil) {
    instance = [[FetchingProgressManager alloc] init];
  }
  return instance;
}

- (id) init
{
  if (instance) {
    [self dealloc];
    return instance;
  }
  
  if ((self = [super init])) {
    instance = self;
  }
  
  return self;
}

/**
 * fetch a specific feed in background.
 */
- (void) fetchFeed: (RSSFeed *) feed
{
#if 0
  if (currentlyFetchedFeeds == 1)
  {
    [NSApp setApplicationIconImage: [NSImage imageNamed: @"rssreader-working.png"]];
  }
#endif

  [feed fetchInBackground];
  
#if 0
  currentlyFetchedFeeds--;
  if (currentlyFetchedFeeds == 0)
  {
    [NSApp setApplicationIconImage: [NSImage imageNamed: @"rssreader.png"]];
  }
#endif
}


/**
 * Fetches all RSSFeed objects in the given array.
 * Returns <em>nothing</em>!
 */
- (void) fetchFeeds: (NSArray *) array
{
  int feedNo;
  int feedCount;
  
  feedCount = [array count];
  
  for (feedNo = 0; feedNo < feedCount; feedNo++)
  {
      
    RSSFeed *feed = [array objectAtIndex: feedNo];
      
    if ([feed isKindOfClass: [RSSReaderFeed class]])
    {
      RSSReaderFeed *rFeed = (RSSReaderFeed*) feed;
      if ([rFeed needsRefresh])
      {
        [self fetchFeed: feed];
      }
    }
    else
    {
      [self fetchFeed: feed];
    }
  }
}
@end
