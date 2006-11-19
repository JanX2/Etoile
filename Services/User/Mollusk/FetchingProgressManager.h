#import <AppKit/AppKit.h>

@interface FetchingProgressManager : NSObject
{
  /* Master queue is where ALL feeds are waiting to be fetched.
   * There is no exception. If feeds have their own schedule,
   * they still need to wait in the queue.
   * They are just added into the queue on their own schedule
   * instead of the global schedule.
   * It won't wait long to be fetced, probably only 2-3 minutes at most
   * if there are hundreds of feeds in queue.
   * Master timer control the fetching scheme.
   * It try to fetch whatever in the queue in a reasonable way
   * in order to avoid jamming the network and data processing.
   * See implementation for details.
   * Do NOT use master timer to control when a given feed to be fetcted.
   * It should be done by adding that given feed in the queue at whenever 
   * it wants to be fetched.
   */ 
  NSTimer *masterTimer;
  NSMutableArray *masterQueue;

  /* Global timer is the one who puts the feed into queue automatically
   * based on user defaults.
   * It is the one user can control in preference.
   */
  NSTimer *globalTimer;
}

+ (FetchingProgressManager *) defaultManager;

/**
 * Fetches all RSSFeed objects in the given array.
 */
- (void) fetchFeeds: (NSArray*) array;

@end
