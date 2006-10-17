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
  [bk setTitle: @"GNUstep"];
  [store addRecord: bk];
  BKBookmark *bk1 = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.etoile-project.org"]];
  [bk1 setTitle: @"Etoile"];
  [store addRecord: bk1];
  BKBookmark *bk2 = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.google.org"]];
  [bk2 setTitle: @"Google"];
  [store addRecord: bk2];

  BKGroup *gp = [[BKGroup alloc] init];
  [gp setValue: @"GNUstep" forProperty: kBKGroupNameProperty];
  [store addRecord: gp];
  [gp addItem: bk];
  [gp addItem: bk1];

  [store save];
  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
}
#endif

#if 0
- (void) testOrdering
{
  NSString *path = @"/tmp/subdir/bookmark_test.bookmark";
  BKBookmarkStore *store = [BKBookmarkStore sharedBookmarkAtPath: path];
  BKBookmark *bk = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.gnustep.org"]];
  [bk setTitle: @"GNUstep"];
  [store addBookmark: bk];
  NSLog(@"%@", [store topLevelRecords]);
  BKBookmark *bk1 = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.etoile-project.org"]];
  [bk1 setTitle: @"Etoile"];
  [store addBookmark: bk1];
  BKBookmark *bk2 = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.google.org"]];
  [bk2 setTitle: @"Google"];
  [store addBookmark: bk2];

  BKGroup *gp = [[BKGroup alloc] init];
  [gp setValue: @"GNUstep" forProperty: kBKGroupNameProperty];
  [store addRecord: gp];
  [gp addItem: bk];
  [gp addItem: bk1];

  [store save];
  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
}
#endif
@end
