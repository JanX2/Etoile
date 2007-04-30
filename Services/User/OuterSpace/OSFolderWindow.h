#import <AppKit/AppKit.h>
#import "OSObject.h"
#import "OSShelfView.h"
#import "OSPathView.h"
#import "OSTrashCanView.h"

@class OSObjectFactory;

typedef enum _OSViewType {
	OSDistributedViewType = 0, /* Default */
	OSBrowserViewType,
	OSTableViewType
} OSViewType;

@interface OSFolderWindow: NSWindow
{
  id <OSObject> object;
  OSViewType type;
  NSView *view; /* table or distributed view */
  NSScrollView *scrollView;
  OSShelfView *shelfView;
  OSPathView *pathView;
  OSTrashCanView *trashCanView;

  NSString *rootPath;
  NSMutableArray *rootPaths;
  OSObjectFactory *factory;
}

/* Return existing window with object, otherwise, create new.
 * Take nil for home directory. */ 
+ (OSFolderWindow *) windowForObject: (id <OSObject>) object
               createNewIfNotExisted: (BOOL) flag;

- (void) setObject: (id <OSObject>) object;
- (id <OSObject>) object;

- (void) setRootPath: (NSString *) rootPath;
- (NSString *) rootPath;

- (void) setType: (OSViewType) type;
- (OSViewType) type;

@end

