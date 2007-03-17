#import <AppKit/AppKit.h>
#import "TrashCanView.h"

@interface TrashCan: NSObject
{
  NSWindow *window;
  NSWindow *appIcon;
  TrashCanView *iconView;
  NSTableView *tableView;
  NSFileManager *fileManager;

  NSString *trashCanPath;
  NSString *trashInfoPath;
  NSString *trashFilesPath;
}

+ (TrashCan *) sharedTrashCan;

/* Actions */
- (void) emptyTrashCan: (id) sender;
- (void) recoverAllFiles: (id) sender;
- (void) recoverSelectedFiles: (id) sender;

- (void) writeFiles: (NSArray *) files;

@end

