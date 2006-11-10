#import <AppKit/AppKit.h>

@interface FetchingProgressManager : NSObject
{
}

+ (FetchingProgressManager *) defaultManager;

/**
 * fetch a specific feed in background
 */
- (void) fetchFeed: (RSSFeed*) feed;

/**
 * Fetches all RSSFeed objects in the given array.
 * Returns <em>nothing</em>!
 */
- (void) fetchFeeds: (NSArray*) array;

@end
