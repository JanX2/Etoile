#import <CoreObject/CoreObject.h>
#import "ETTextProtocols.h"

@class NSMutableSet;
@class NSMutableDictionary;
@class ETStyleTransformer;

@interface ETTextDocument : COObject 
{
	NSMutableDictionary *styleTransformers;
	NSMutableSet *types;
}
@property (nonatomic, retain) id<ETText> text;
- (void)registerTransformer: (ETStyleTransformer*)aTransformer
              forStyleNamed: (NSString*)styleName;
- (id)typeFromDictionary: (NSDictionary*)aDictionary;
@end
