/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MainController.h"

#import "ArticleViewing.h"


MainController* singleton = nil;

MainController* getMainController()
{
  if (singleton == nil)
    singleton = [[MainController alloc] init];
  
  return singleton;
}

@implementation MainController

- (id) init
{
  self = [super init];
  if (singleton != nil)
    {
      [self dealloc];
      return singleton;
    }
  
  // Register refreshing of main table for feed changed notifs
  [[NSNotificationCenter defaultCenter] addObserver: self
                      selector: @selector(refreshMainTable:)
                      name: @"FeedFetchedNotification"
                      object: nil];
  
  // real init here
  fetchingProgressManager = nil;
  
  singleton = self;
  return singleton;
}

- (id) articleView
{
  return AUTORELEASE(RETAIN(articleView));
}

- (void) goThereButton: (id)sender
{
  if ([RSSArticle currentlyViewed] == nil)
    {
      NSLog(@"You need to select the article you want to read.");
      return;
    }
    
  [[NSWorkspace sharedWorkspace]
    openURL: [NSURL URLWithString: [[RSSArticle currentlyViewed] url]]];
}


- (void) refreshMainTable: (id) sender
{
    [self refreshMainTable];
}

- (void) refreshMainTable
{
  [RSSArticle viewNone];
  [mainTable deselectAll: self];
  [mainTable reloadData];
  [mainTable setNeedsDisplay: YES];
}

- (void) reloadButton: (id)sender
{
  [[self fetchingProgressManager]
    fetchFeeds: [getFeedList() feedList]];
  
  [getFeedList() setArticleListDirty: YES];
  [self refreshMainTable];
}


// Fetching Progress Manager Singleton stuff
- (void) fetchingProgressManager: (FetchingProgressManager*) aFPM
{
  RELEASE(fetchingProgressManager);
  fetchingProgressManager = RETAIN(aFPM);
}

- (FetchingProgressManager*) fetchingProgressManager
{
  return AUTORELEASE(RETAIN(fetchingProgressManager));
}



// Error Log Controller Singleton Stuff
- (void) errorLogController: (ErrorLogController*) aELC
{
  RELEASE(errorLogController);
  errorLogController = RETAIN(aELC);
}

- (ErrorLogController*) errorLogController
{
  return AUTORELEASE(RETAIN(errorLogController));
}


@end
