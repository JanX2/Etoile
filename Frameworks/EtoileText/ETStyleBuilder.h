#import <Foundation/NSObject.h>

@class NSMutableDictionary;
@class NSDictionary;

@interface ETStyleBuilder : NSObject
{
	NSMutableDictionary *style;
}
- (void)addAttributesForStyle: (id)style;
- (void)addCustomAttributes: (NSDictionary*)attributes;
- (NSDictionary*)style;
@end
