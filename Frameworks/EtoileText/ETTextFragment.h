#import "ETTextProtocols.h"
#import <CoreObject/COObject.h>

@interface ETTextFragment : COObject<ETText>
{
	NSMutableString *text;
}
@property (nonatomic, assign) id<ETTextGroup> parent;
- (id)initWithString: (NSString*)string;
@end
