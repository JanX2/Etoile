#import <RSSKit/RSSKit.h>
#import "FetchingProgressManager.h"
#import "RSSReaderFeed.h"
#import "FeedList.h"
#import "GNUstep.h"
#import "Global.h"

static FetchingProgressManager* instance;

@interface FetchingProgressManager (Private)
- (void) automaticRefreshIntervalChanged: (NSNotification *) not;
@end

@implementation FetchingProgressManager

/** Private **/
- (void) scheduledFetchFeed: (NSTimer *) timer
{
  /* Fetch based on master timer */
  if ([masterQueue count] > 0) {
    RSSFeed *feed = [masterQueue objectAtIndex: 0];
    NSLog(@"Fetching %@", [feed feedURL]);
    [feed fetchInBackground];
    [masterQueue removeObject: feed];
  } else {
    /* Nothing in queue. Destroy timer */
    [masterTimer invalidate];
    DESTROY(masterTimer);
    [NSApp setApplicationIconImage: [NSImage imageNamed: @"rssreader.png"]];
  }
}

- (void) globalTimerAction: (NSTimer *) timer
{
  NSLog(@"globalTimerAction %@", timer);
  /* Put everything in queue */
  [self fetchFeeds: [[FeedList feedList] feeds]];
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

    [[NSNotificationCenter defaultCenter]
          addObserver: self
          selector: @selector(automaticRefreshIntervalChanged:)
          name: RSSReaderAutomaticRefreshIntervalChangeNotification
          object: nil];
  
    [self automaticRefreshIntervalChanged: nil];

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
      if ([(RSSReaderFeed *)feed needsRefresh] == NO)
      {
        continue;
      }
    }
    if ([masterQueue containsObject: feed] == NO) {
      [masterQueue addObject: feed];
    }
  }
  NSLog(@"queue %d", [masterQueue count]);
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

- (void) automaticRefreshIntervalChanged: (NSNotification *) not
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  float f = [defaults floatForKey: RSSReaderAutomaticRefreshIntervalDefaults];
  /* Stop current global timer */
  if (globalTimer) {
    [globalTimer invalidate];
    DESTROY(globalTimer);
  }
  if (f > 0) {
    /* Fire again with different schedule */
    ASSIGN(globalTimer, [NSTimer scheduledTimerWithTimeInterval: (f * 3600)
                                 target: self
                                 selector: @selector(globalTimerAction:)
                                 userInfo: nil
                                 repeats: YES]);
    NSLog(@"Fire every %f hour", f);
  }
}

@end
