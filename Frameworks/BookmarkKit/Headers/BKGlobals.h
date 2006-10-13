#import <Foundation/Foundation.h>

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
@end

