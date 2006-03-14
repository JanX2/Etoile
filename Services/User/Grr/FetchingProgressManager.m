/* -*-objc-*-
 * All Rights reserved
 */

#import <AppKit/AppKit.h>
#import <RSSKit/RSSKit.h>


#import "FetchingProgressManager.h"
#import "FeedManagement.h"
#import "MainController.h"
#import "RSSReaderFeed.h"
#import "FeedList.h"

#define NO_MULTITHREADING YES
#undef NO_MULTITHREADING
#define DEBUG YES


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
    [[FetchingProgressManager alloc] init];
  }
  
  return instance;
}

-init
{
  if (self = [super init])
    {
      [getMainController() fetchingProgressManager: self];
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



-(void) fetchFeedThreaded: (RSSFeed*) feed
{
#ifdef NO_MULTITHREADING
  [self fetchFeed: feed];
#else
  [NSThread detachNewThreadSelector: @selector(fetchFeed:)
	    toTarget: self
	    withObject: feed];
#endif
}

/**
 * fetch a specific feed. Used for threading
 */
-(void)fetchFeed: (RSSFeed*) feed
{
  NSAutoreleasePool* threadAutoreleasePool;
  NSLock* lock;
  enum RSSFeedError feedError;
  
  threadAutoreleasePool = [[NSAutoreleasePool alloc] init];
  
  
  lock = getCurrentlyFetchedFeedsLock();
  
  NSLog(@"thread fetching %@ just started", feed);
  
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
    [feed fetch];
    feedError = [feed lastError];
    
    if (feedError != RSSFeedErrorNoError)
      {
	[[ErrorLogController instance]
	  logString:
	    [NSString stringWithFormat:
			@"%@ fetching failed: %@\n", [feed description],
		      [FetchingProgressManager stringForError: feedError]]];
      }
  }
  NS_HANDLER {
    [[ErrorLogController instance]
      logString:
	[NSString stringWithFormat: @"%@ fetching failed: %@\n",
		  [feed description], [localException reason]]];
  }
  NS_ENDHANDLER;
  
  [[FeedManagement instance] refreshFeedTable];
  [getFeedList() setArticleListDirty: YES];
  
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
  
    
  RELEASE(threadAutoreleasePool);
  NSLog(@"tap exit release");
  
#ifdef NO_MULTITHREADING
#ifdef DEBUG
  NSLog(@"NO Multithreading");
#endif // DEBUG
#else  // NO_MULTITHREADING
#ifdef DEBUG
  NSLog(@"Multithreading: fetching %@ thread just exited", feed);
#endif // DEBUG
  [NSThread exit];
#endif // NO_MULTITHREADING
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
      
      if ([feed isSubclassedFeed])
	{
	  register RSSReaderFeed* rFeed;
	  
	  rFeed = (RSSReaderFeed*) feed;
	  if ([rFeed needsRefresh])
	    {
	      [self fetchFeedThreaded: feed];
	    }
	}
      else
	{
	  [self fetchFeedThreaded: feed];
	}
    }
}
@end
