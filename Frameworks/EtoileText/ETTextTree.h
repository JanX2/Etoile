#import "ETTextProtocols.h"
#import <CoreObject/COObject.h>

@interface ETTextTree : COObject <ETText,ETTextGroup>
{
	NSMutableArray *children;
}
@property (nonatomic, assign) id<ETTextGroup> parent;
+ (ETTextTree*)textTreeWithChildren: (NSArray*)anArray;
- (void)appendTextFragment: (id<ETText>)aFragment;
@end

