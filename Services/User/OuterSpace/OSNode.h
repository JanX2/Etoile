#import "OSObject.h"

/* OSNode represents a node on file system.
 * It may not exist yet, but must be able to be created on file system.
 * It can be a directory of file. */
@interface OSNode: NSObject <OSObject>
{
  NSString *path;
  NSFileManager *fm;
  BOOL isDirectory;
  BOOL isExisted;
  BOOL setHidden;
  NSDate *lastModificationDate;

  /* Cache */
  NSArray *children;
}

/* Use last modification date on directory to decide */
- (BOOL) needsUpdate;

- (void) setPath: (NSString *) path;
- (NSString *) path;

- (void) showHiddenFiles: (BOOL) flag;
- (BOOL) isHiddenFilesShown;
@end

