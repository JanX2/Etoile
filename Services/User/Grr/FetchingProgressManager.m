#import <RSSKit/RSSKit.h>
#import "FetchingProgressManager.h"
#import "RSSReaderFeed.h"
#import "FeedList.h"
#import "GNUstep.h"
#import "Global.h"

//* The number of currently fetched feeds
int currentlyFetchedFeeds = 0;

/**
 * A lock for the number of currently fetched feeds.
 * Get this lock by calling getCurrentlyFetchedFeedsLock().
 */
NSLock* currentlyFetchedFeedsLock = nil;

NSLock* getCurrentlyFetchedFeedsLock()
{
  if (currentlyFetchedFeedsLock == nil)
    {
      currentlyFetchedFeedsLock = [[NSLock alloc] init];
    }
  
  return currentlyFetchedFeedsLock;
}



FetchingProgressManager* instance;

@implementation FetchingProgressManager

+(FetchingProgressManager*) instance
{
  if (instance == nil) {
    instance = [[FetchingProgressManager alloc] init];
  }
  return instance;
}

-(id)init
{
  if ((self = [super init]))
    {
      instance = self;
    }
  
  return self;
}


// get an error string for an error message
+(NSString*) stringForError: (int) error
{
  switch (error)
    {
    case RSSFeedErrorNoError:
      return @"No Error";
      break;
      
    case RSSFeedErrorNoFetcherError:
      return @"Got no information on how to fetch this feed.";
      break;
      
    case RSSFeedErrorMalformedURL:
      return @"Malformed feed URL";
      break;
      
    case RSSFeedErrorDomainNotKnown:
      return @"Cannot resolve domain name";
      break;
      
    case RSSFeedErrorServerNotReachable:
      return @"Server not reachable.";
      break;
      
    case RSSFeedErrorDocumentNotPresent:
      return @"Document not present on server.";
      break;
      
    case RSSFeedErrorMalformedRSS:
      return @"Malformed RSS format";
      break;
      
    default:
      return @"Unknown error. (Update RSSKit?)";
      break;
    }
}

/**
 * fetch a specific feed. Used for threading
 */
-(void)fetchFeed: (RSSFeed*) feed
{
  CREATE_AUTORELEASE_POOL(x);

  NSLock* lock;
  enum RSSFeedError feedError;
  
  lock = getCurrentlyFetchedFeedsLock();
  
  [lock lock];
  currentlyFetchedFeeds++;
  if (currentlyFetchedFeeds == 1)
    {
      [NSApp
	performSelectorOnMainThread: @selector(setApplicationIconImage:)
	withObject: [NSImage imageNamed: @"rssreader-working.png"]
	waitUntilDone: YES];
    }
  [lock unlock];
  
  NS_DURING {
    [feed fetchInBackground];
    feedError = [feed lastError];
    
    if (feedError != RSSFeedErrorNoError)
      {
        NSString *s = [NSString stringWithFormat:
			@"%@ fetching failed: %@\n", [feed description],
		      [FetchingProgressManager stringForError: feedError]];
        [[NSNotificationCenter defaultCenter]
                 postNotificationName: RSSReaderLogNotification
                 object: s]; 
      }
  }
  NS_HANDLER {
       NSString *s = [NSString stringWithFormat: @"%@ fetching failed: %@\n",
		  [feed description], [localException reason]];
        [[NSNotificationCenter defaultCenter]
                 postNotificationName: RSSReaderLogNotification
                 object: s]; 
  }
  NS_ENDHANDLER;
  
  [lock lock];
  currentlyFetchedFeeds--;
  if (currentlyFetchedFeeds == 0)
    {
      NSLog(@"icon reset");
      [NSApp
	performSelectorOnMainThread: @selector(setApplicationIconImage:)
	withObject: [NSImage imageNamed: @"NSApplicationIcon"]
	waitUntilDone: YES];
    }
  [lock unlock];
  
  DESTROY(x);  
}


/**
 * Fetches all RSSFeed objects in the given array.
 * Returns <em>nothing</em>!
 */
-(void)fetchFeeds: (NSArray*) array
{
  int               feedNo;
  int               feedCount;
  
  feedCount = [array count];
  
  for (feedNo=0; feedNo<feedCount; feedNo++)
    {
      RSSFeed* feed;
      
      feed = [array objectAtIndex: feedNo];
      
      if ([feed isKindOfClass: [RSSReaderFeed class]])
	{
	  register RSSReaderFeed* rFeed;
	  
	  rFeed = (RSSReaderFeed*) feed;
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
