
#import "PopplerDocumentTest.h"
#import "TestSettings.h"
#import <PopplerKit/PopplerKit.h>
#import <Foundation/NSException.h>


@implementation PopplerDocumentTest

- (void) testOpenDocument
{
   PopplerDocument* doc = [PopplerDocument documentWithPath: kTestDocument];
   [self assertNotNil: doc];
   [self assertInt: kTestDocumentPageCount equals: [doc countPages]];
}

- (void) testOpenNonExistingDocument
{
   NS_DURING
      [PopplerDocument documentWithPath: kNonExistentDocument];
      [self fail: @"exception expected"];
   NS_HANDLER
      [self assert: [localException name] equals: PopplerException];
   NS_ENDHANDLER
}

- (void) testOpenNilPath
{
   NS_DURING
      [PopplerDocument documentWithPath: nil];
      [self fail: @"exception expected"];
   NS_HANDLER
      [self assert: [localException name] equals: NSInvalidArgumentException];
   NS_ENDHANDLER
}

- (void) testGetPages
{
   PopplerDocument* doc = [PopplerDocument documentWithPath: kTestDocument];
   
   int i;
   for (i = 1; i <= [doc countPages]; i++)
   {
      PopplerPage* page = [doc page: i];
      [self assertNotNil: page message: [NSString stringWithFormat: @"page %d is nil", i]];
      [self assert: page same: [doc page: i]];
      [self assertInt: [page index] equals: i];
      [self assert: [page document] same: doc];
   }
}

- (void) testGetPageWithInvalidIndex
{
   PopplerDocument* doc = [PopplerDocument documentWithPath: kTestDocument];

   NS_DURING
      [doc page: 0];
      [self fail: @"exception expected"];
   NS_HANDLER
      [self assert: [localException name] equals: NSInvalidArgumentException];
   NS_ENDHANDLER
   
   NS_DURING
      [doc page: [doc countPages] + 1];
      [self fail: @"exception expected"];
   NS_HANDLER
      [self assert: [localException name] equals: NSInvalidArgumentException];
   NS_ENDHANDLER
}

@end
