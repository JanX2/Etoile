#import <BookmarkKit/BKBookmarkStore.h>
#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>

@interface TestBookmarkStore: NSObject <UKTest>
@end

@implementation TestBookmarkStore
- (void) testBasic
{
  NSString *path = [[BKBookmarkStore sharedBookmarkStore] path];
  UKNotNil(path);
}
@end
