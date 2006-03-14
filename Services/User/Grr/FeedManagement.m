/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "FeedManagement.h"

#import "FeedSelection.h"
#import "FeedList.h"
#import "MainController.h"

#import "RSSReaderFeed.h"
#import "RSSReaderArticle.h"

// private
FeedManagement* feedManagementSingleton;

@implementation FeedManagement

+(id) instance
{
  if (feedManagementSingleton == nil)
    {
      feedManagementSingleton =
	[[FeedManagement alloc] init];
    }
  
  return feedManagementSingleton;
}

-(id) init
{
  if (self = [super init])
    {
      feedManagementSingleton = self;
    }
  
  /* Load nib */
  [NSBundle loadNibNamed: @"AddFeedPanel" owner: self];
  [NSBundle loadNibNamed: @"CleanUpFeedPanel" owner: self];
  [NSBundle loadNibNamed: @"FeedPreferencesPanel" owner: self];
  [NSBundle loadNibNamed: @"FeedManagement" owner: self];
  
  return self;
}


- (void) refreshFeedTable
{
  [RSSFeed unselectAll];
  [feedTable deselectAll: self];
  [feedTable reloadData];
}


- (void) deleteFeed: (id)sender
{
  RSSFeed* feed;
  
  feed = [RSSFeed selectedFeed];
  
  if (feed == nil)
    return; // nothing to delete, since nothing selected.
  
  [getFeedList() removeFeed: feed];
  
  [RSSFeed unselectAll];
  [feedTable deselectAll: self];
  
  [feedTable reloadData];
  [feedTable setNeedsDisplay: YES];
  
  [getMainController() refreshMainTable];
}

- (void) openFeedManagementWindow: (id)sender
{
	NSLog(@"OpenFeedManagement");
  [feedManagementWindow orderFront: self];
}

- (void) openFeedAddingWindow: (id)sender
{
  [URLInputField setStringValue: @""];
  [addFeedWindow orderFront: self];
}

- (void) openCleanUpFeedWindow: (id) sender
{
  [cleanUpFeedWindow orderFront: self];
}

- (void) openFeedPreferencesWindow: (id) sender
{
  [feedPreferencesWindow orderFront: self];
}

/**
 * FIXME: Rewrite this (and probably put the functionality
 * somewhere into RSSFeed or RSSReaderFeed). This is currently
 * highly inefficient since we got lots of allocations and
 * deallocations!
 */
- (void) cleanUpFeed: (id)sender
{
  NSEnumerator* enumerator;
  RSSArticle* article;
  RSSFeed* feed;
  NSDate* date;
  int i;
  BOOL dirty;
  
  NSLog(@"FIXME: rewrite cleanUpFeed: in FeedManagement.m!");
  
  feed = [RSSFeed selectedFeed];
  
  if (feed==nil)
    {
      return;
    }
  
  // one week ago
  date = [NSDate dateWithTimeIntervalSinceNow: -804800];
  
  dirty = NO;
  
  enumerator = [feed articleEnumerator];
  while (article = [enumerator nextObject])
    {
      if ([[article date] compare: date] == NSOrderedAscending)
	{
	  [feed removeArticle: article];
	  dirty = YES;
	}
    }
  
  if (dirty)
    {
      [getFeedList() setArticleListDirty: YES];
      [getMainController() refreshMainTable];
    }
  
  // close the window
  [cleanUpFeedWindow performClose: self];
}


- (void) addFeed: (id)sender
{
  NSString* urlString;
  NSURL* url;
  RSSFeed* feed;
  
  urlString = [URLInputField stringValue];
  
  // create the URL...
  url = [NSURL URLWithString: [NSString stringWithString: urlString]];
  
  // create the feed
  feed = AUTORELEASE([[RSSReaderFeed alloc] initWithURL: url]);
  [feed setAutoClear: NO];
  
  // actually add the feed
  [getFeedList() addFeed: feed];
  
  // close the window
  [addFeedWindow performClose: self];
}


@end
