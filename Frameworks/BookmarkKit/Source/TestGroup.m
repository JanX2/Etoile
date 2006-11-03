#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <BookmarkKit/BookmarkKit.h>

@interface TestGroup: NSObject <UKTest>
@end

@implementation TestGroup
- (void) testModification
{
  BKBookmarkStore *store = [BKBookmarkStore sharedBookmarkStore];
  BKBookmark *bk = [BKBookmark bookmarkWithURL: [NSURL URLWithString: @"http://www.gnustep.org"]];
  UKTrue([store addRecord: bk]);
  UKIntsEqual([bk isTopLevel], BKTopLevel);
  BKGroup *gp = [[BKGroup alloc] init];
  [gp setName: @"Group"];
  UKTrue([store addRecord: gp]);
  UKIntsEqual([gp isTopLevel], BKTopLevel);
  BKGroup *gp1 = [[BKGroup alloc] init];
  [gp1 setName: @"Group1"];
  UKTrue([store addRecord: gp1]);
  UKIntsEqual([gp1 isTopLevel], BKTopLevel);
  UKStringsEqual(@"Group", [gp name]);
  UKStringsEqual(@"Group1", [gp1 name]);

  UKTrue([gp addItem: bk]);
  UKFalse([gp1 addItem: bk]);
  UKIntsEqual([bk isTopLevel], BKNotTopLevel);
  UKTrue([gp removeItem: bk]);
  UKIntsEqual([bk isTopLevel], BKTopLevel);
  UKTrue([gp1 addItem: bk]);
  UKIntsEqual([bk isTopLevel], BKNotTopLevel);
  UKTrue([gp addSubgroup: gp1]);
  UKIntsEqual([gp1 isTopLevel], BKNotTopLevel);
}
@end
