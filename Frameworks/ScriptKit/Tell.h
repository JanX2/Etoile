#import <Foundation/NSObject.h>

@interface Tell : NSObject {}
/**
 * Looks up anApp's scripting dictionary and passes it to aBlock.
 */
+ (void) application:(NSString*)anApp to:(id)aBlock;
@end
