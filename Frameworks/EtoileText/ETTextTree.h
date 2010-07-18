#import "ETTextProtocols.h"
#import <CoreObject/COObject.h>

/**
 * A tree of structured text.  This class does not contain text directly.  Text
 * is stored in children; this class contains only children and attributes.
 */
@interface ETTextTree : COObject <ETText,ETTextGroup,ETCollection>
{
	NSMutableArray *children;
}
/**
 * Creates a new tree node with the specified children.
 */
+ (ETTextTree*)textTreeWithChildren: (NSArray*)anArray;
/**
 * Adds a new text tree node at the end of this run.
 */
- (void)appendTextFragment: (id<ETText>)aFragment;
@end

