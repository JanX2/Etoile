#import <Foundation/Foundation.h>

/* Implement trash info specification (.trashinfo) */

@interface TrashInfo: NSObject
{
  NSMutableArray *lines; /* Keep the rest of file */
  NSURL *url;
  NSCalendarDate *date;
}

/* It should be absolute path according to specification. */
- (void) setPath: (NSString *) string;
- (NSString *) path;

- (void) setDeletionDate: (NSCalendarDate *) date;
- (NSCalendarDate *) deletionDate;

- (id) initWithContentsOfFile: (NSString *) path;
- (BOOL) writeToFile: (NSString *) p;

@end

