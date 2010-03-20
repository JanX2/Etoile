#import <CoreObject/CoreObject.h>
#import "ETTextProtocols.h"

@class NSMutableSet;
@class NSMutableDictionary;
@class ETStyleTransformer;

@interface ETTextDocument : COObject 
{
	NSMutableDictionary *styleTransformers;
	NSMutableSet *styles;
}
@property (nonatomic, retain) id<ETText> text;
- (void)registerTransformer: (ETStyleTransformer*)aTransformer
              forStyleNamed: (NSString*)styleName;
- (id)styleFromDictionary: (NSDictionary*)aDictionary;
@end
