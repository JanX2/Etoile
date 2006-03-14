// -*-objc-*-
/* All Rights reserved */

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface FetchingProgressManager : NSObject
{
  NSString* feedName;
}

+(FetchingProgressManager*) instance;

-init;


// get an error string for an error message
+(NSString*) stringForError: (int) error;

/**
 * fetch a specific feed. Used for threading
 */
-(void) fetchFeed: (RSSFeed*) feed;

/**
 * Fetches all RSSFeed objects in the given array.
 * Returns <em>nothing</em>!
 */
-(void) fetchFeeds: (NSArray*) array;

@end
