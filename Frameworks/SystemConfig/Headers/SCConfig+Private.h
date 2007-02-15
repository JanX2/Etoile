
#import <Foundation/NSString.h>
#import "SCConfig.h"

@interface SCConfigElement (Private)

/** 
 * Internal SCConfig method that makes it easier for
 * implementers to send errors.
 */
-(void) notifyErrorCode: (int) errorCode
            description: (NSString*) description;

@end


