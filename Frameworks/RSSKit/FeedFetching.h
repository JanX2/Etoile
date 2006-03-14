// -*-objc-*-

#import "RSSFeed.h"

/**
 * The ,,Fetching'' category of RSSFeed contains methods
 * for the RSSFeed class, which are responsible for fetching
 * and parsing feeds.
 */
@interface RSSFeed (Fetching)

/**
 * Returns the last error.
 * Guaranteed to return the last fetching result.
 */
-(enum RSSFeedError) lastError;

// get the document from the http server
-(enum RSSFeedError) setError: (enum RSSFeedError) err;

/**
 * Fetches the feed from the web (using NSURL).
 *
 * @return An error number (of type enum RSSFeedError)
 * @see NSURL
 * @see RSSFeedError
 */
-(enum RSSFeedError) fetch;

@end
