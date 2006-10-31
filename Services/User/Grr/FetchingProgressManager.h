#import <AppKit/AppKit.h>

@interface FetchingProgressManager : NSObject
{
}

+ (FetchingProgressManager *) instance;

// get an error string for an error message
+ (NSString*) stringForError: (int) error;

/**
 * fetch a specific feed. Used for threading
 */
- (void) fetchFeed: (RSSFeed*) feed;

/**
 * Fetches all RSSFeed objects in the given array.
 * Returns <em>nothing</em>!
 */
- (void) fetchFeeds: (NSArray*) array;

@end
