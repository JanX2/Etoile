/* All Rights reserved */

// -*-objc-*-

#import "FeedList.h"
#import <AppKit/AppKit.h>

#import "FetchingProgressManager.h"
#import "ErrorLogController.h"

@interface MainController : NSObject
{
  id articleView;
  id mainTable;
  
  FetchingProgressManager* fetchingProgressManager;
  ErrorLogController* errorLogController;
}

-init;

- (id) articleView;

- (void) refreshMainTable;

- (void) goThereButton: (id)sender;
- (void) reloadButton: (id)sender;

- (void) fetchingProgressManager: (FetchingProgressManager*) aFPM;
- (FetchingProgressManager*) fetchingProgressManager;

- (void) errorLogController: (ErrorLogController*) aELC;
- (ErrorLogController*) errorLogController;

@end

MainController* getMainController();

