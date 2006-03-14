// -*-objc-*-
/* Guenther Noack, GPL */

#import <AppKit/AppKit.h>
#import "RSSReaderFeed.h"

@interface FeedPreferencesManager : NSObject
{
  id minUpdateIntervalDragger;
  id minUpdateIntervalText;
  id urlTextField;
  id prefPanelHeadline;
  id clearFeedControl;
}

- (id) init;
+ (FeedPreferencesManager*) instance;

- (void) clearFeedUpdated: (id) sender;

- (void) selectedFeedUpdated: (RSSFeed*) feed;

- (void) minUpdateIntervalUpdated: (id)sender;
- (void) newFeedURL: (id)sender;
@end
