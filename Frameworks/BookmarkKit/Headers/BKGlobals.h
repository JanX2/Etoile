#import <Foundation/Foundation.h>

extern NSString *const kBKBookmarkURLProperty;
extern NSString *const kBKBookmarkTitleProperty;
extern NSString *const kBKBookmarkLastVisitedDateProperty;
extern NSString *const kBKGroupNameProperty;
extern NSString *const kBKTopLevelOrderProperty; /* order of top level record */

/* Top level is used to cache items without parent.
 * It is equivalent to -parentGroups.
 */
typedef enum _BKTopLevelType
{
  BKUndecidedTopLevel = -1, // parent group is not decided
  BKNotTopLevel = 0, // with parent group
  BKTopLevel = 1 // without parent group
} BKTopLevelType;

@protocol BKTopLevel <NSObject>
- (BKTopLevelType) isTopLevel;
- (void) setTopLevel: (BKTopLevelType) level;
- (NSComparisonResult) compareTopLevelOrder: (CKRecord <BKTopLevel> *) another;
@end

