#import "OSNode.h"

/* This is physical node, but it does the trick to presents trashed files.
   Therefore, it heavily overrides OSNode.
   In general, OSNode does not display UI, but this is an exception. */
@interface OSTrashCan: OSNode
{
  NSString *trashCanPath;
  NSString *trashInfoPath;
  NSString *trashFilesPath;
}

/* Actions */
- (void) emptyTrashCan: (id) sender;
- (void) recoverAllFiles: (id) sender;
- (void) recoverSelectedFiles: (id) sender;

@end

