#import <BookmarkKit/BookmarkKit.h>
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

#if 0
- (void) testSave
{
  NSString *path = @"/tmp/subdir/bookmark_test.bookmark";
  BKBookmarkStore *store = [BKBookmarkStore sharedBookmarkAtPath: path];
  BKBookmark *bk = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.gnustep.org"]];
  [store addRecord: bk];
  BKBookmark *bk1 = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.etoile-project.org"]];
  [store addRecord: bk1];
  BKBookmark *bk2 = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.google.org"]];
  [store addRecord: bk2];

  BKGroup *gp = [[BKGroup alloc] init];
  [gp setValue: @"GNUstep" forProperty: kCKGroupNameProperty];
  [store addRecord: gp];
  [gp addItem: bk];
  [gp addItem: bk1];

  [store save];
  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
}
#endif
@end
