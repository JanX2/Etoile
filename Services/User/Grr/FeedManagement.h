/* -*-objc-*- */
/* All Rights reserved */

#import <AppKit/AppKit.h>

@interface FeedManagement : NSObject
{
  id feedTable;
  id URLInputField;
  id addFeedWindow;
  id cleanUpFeedWindow;
  id feedPreferencesWindow;
  id feedManagementWindow;
}

+(id) instance;
-(id) init;

- (void) openFeedManagementWindow: (id) sender;
- (void) openFeedAddingWindow: (id)sender;
- (void) cleanUpFeed: (id)sender;

- (void) refreshFeedTable;


- (void) deleteFeed: (id)sender;
- (void) addFeed: (id)sender;


@end
