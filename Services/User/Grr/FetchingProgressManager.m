#import <RSSKit/RSSKit.h>
#import "FetchingProgressManager.h"
#import "RSSReaderFeed.h"
#import "FeedList.h"
#import "GNUstep.h"
#import "Global.h"

static FetchingProgressManager* instance;

@implementation FetchingProgressManager

/** Private **/
- (void) scheduledFetchFeed: (NSTimer *) timer
{
  /* Fetch */
  if ([masterQueue count] > 0) {
    RSSFeed *feed = [masterQueue objectAtIndex: 0];
    [feed fetchInBackground];
    [masterQueue removeObject: feed];
  } else {
    /* Nothing in queue. Destroy timer */
    [masterTimer invalidate];
    DESTROY(masterTimer);
    [NSApp setApplicationIconImage: [NSImage imageNamed: @"rssreader.png"]];
  }
}

/** End of Private **/

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

    masterQueue = [[NSMutableArray alloc] init];

    return self;
  }
  
  [self dealloc];
  return nil;
}

- (void) dealloc
{
  DESTROY(masterQueue);
  DESTROY(masterTimer);
  [super dealloc];
}

/**
 * Fetches all RSSFeed objects in the given array.
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
        [masterQueue addObject: feed];
      }
    }
    else
    {
      [masterQueue addObject: feed];
    }
  }
  if ((feedCount > 0) && (masterTimer == nil)) {
    /* Initial master timer. 
     * Currently, we call it every second 
     * until every feed in queue is fetched. */
    ASSIGN(masterTimer, [NSTimer scheduledTimerWithTimeInterval: 1
                                 target: self
                                 selector: @selector(scheduledFetchFeed:)
                                 userInfo: nil
                                 repeats: YES]);
    [NSApp setApplicationIconImage: [NSImage imageNamed: @"rssreader-working.png"]];
  }
}
@end
