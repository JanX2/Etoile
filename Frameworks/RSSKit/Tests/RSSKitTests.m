/** -*-objc-*-
 */

#import "RSSKitTests.h"


@implementation RSSFeed (Resources)
+(id)feedWithResource: (NSString*)aResourceName
{
  return AUTORELEASE([[self alloc] initWithResource: aResourceName]);
}
-(id)initWithResource: (NSString*)aResourceName
{
  NSBundle* testsBundle = [NSBundle bundleForClass: [RSSKitTests class]];
  NSString* res = [testsBundle pathForResource: aResourceName ofType: @"xml"];
  NSLog(@"init with file path: %@", res);
  
  NSURL* url = [NSURL fileURLWithPath: res];
  
  NSLog(@"init with URL: %@", url);
  return [self initWithURL: url];
}
@end



@implementation RSSKitTests

- (void) testNothing
{
  UKFail();
}

@end

