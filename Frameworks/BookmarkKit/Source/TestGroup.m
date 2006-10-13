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
  UKIntsEqual([bk isTopLevel], BKTopLevel);
  UKTrue([store addRecord: bk]);
  BKGroup *gp = [[BKGroup alloc] init];
  UKIntsEqual([gp isTopLevel], BKTopLevel);
  UKTrue([store addRecord: gp]);
  BKGroup *gp1 = [[BKGroup alloc] init];
  UKIntsEqual([gp1 isTopLevel], BKTopLevel);
  UKTrue([store addRecord: gp1]);

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
