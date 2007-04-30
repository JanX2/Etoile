#import "OSNode.h"

/* Implement trash info specification (.trashinfo).
   Its path point to the real file. */
@interface OSTrashNode: OSNode
{
  NSMutableArray *lines; /* Keep the rest of file */
  NSURL *url;
  NSCalendarDate *date;
  NSString *trashInfoPath;
}

- (id) initWithContentsOfFile: (NSString *) path;
- (BOOL) writeTrashInfo;
- (BOOL) removeTrashInfo; /* Call it only when trash node does not exist */

- (void) setOriginalPath: (NSString *) path;
- (NSString *) originalPath;

- (void) setDeletionDate: (NSCalendarDate *) date;
- (NSCalendarDate *) deletionDate;

@end

