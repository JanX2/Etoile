#import <Foundation/Foundation.h>

@class ETTextTree;
@class ETTextFragment;

@interface ETTextTreeBuilder : NSObject
{
	NSMutableArray *textTypeStack;
	id<ETText> insertNode;
}
@property (nonatomic, retain) ETTextTree *textTree;
- (void)startNodeWithStyle: (id)aStyle;
- (void)endNode;
- (void)appendString: (NSString*)aString;
@end
