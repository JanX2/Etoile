#import <BookmarkKit/BookmarkKit.h>
#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>

@interface TestBookmark: NSObject <UKTest>
@end

@implementation TestBookmark
- (void) testURL
{
  /* Test this because NSURL is stored as NSString internally.
   * Need to make sure it can be converted back to NSURL correctly */
  NSString *path = @"file:///tmp/abc/xxx/123.rtf";
  NSURL *url = [NSURL URLWithString: path];
  BKBookmark *bk = [BKBookmark bookmarkWithURL: url];
  NSURL *result = [bk URL];
  UKTrue([url isEqual: result]);
  UKTrue([result isFileURL]);

  path = @"http://www.gnustep.org";
  url = [NSURL URLWithString: path];
  bk = [BKBookmark bookmarkWithURL: url];
  result = [bk URL];
  UKTrue([url isEqual: result]);
  UKFalse([result isFileURL]);
}

@end
