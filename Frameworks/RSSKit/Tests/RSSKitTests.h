/** -*-objc-*-
 * RSSKit Test Suite by Guenther Noack
 *
 */

#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <RSSKit/RSSKit.h>


/**
 * A category that enables RSS Feeds to read feeds from the resources
 */
@interface RSSFeed (Resources)
+(id)feedWithResource: (NSString*)aResourceName;
-(id)initWithResource: (NSString*)aResourceName;
@end


@interface RSSKitTests : NSObject <UKTest> {
}

- (void) testNothing;
@end

