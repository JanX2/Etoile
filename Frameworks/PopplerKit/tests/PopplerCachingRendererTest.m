
#import "PopplerCachingRendererTest.h"
#import "TestSettings.h"

// NOTE: as PopplerCachingRenderer is based on MkLRUCache we don't
//       test the caching behavior here (eg. what happens if the
//       size of the objects in the cache exceeds the maximum size).
//       MkLRUCache has it's own test in MissingKit so we can "trust"
//       it here.


@implementation PopplerCachingRendererTest

- (void) setUp
{
   renderer = nil;
   document = [[PopplerDocument alloc] initWithPath: kTestDocument];
   renderer = [[PopplerCachingRenderer alloc] initWithDocument: document];
}

- (void) tearDown
{
   [renderer release];
   [document release];
}

- (void) testRenderSamePageMultipleTimes
{
   PopplerPage* page = [document page: 1];
   
   id result1 = [renderer renderPage: page scale: 1.0];
   [self assertNotNil: result1];
   
   int i;
   for (i = 1; i <= 2; i++)
   {
      id result = [renderer renderPage: page scale: 1.0];
      [self assertNotNil: result];
      [self assert: result same: result1];
   }
}

- (void) testRenderPageSequence
{
   PopplerPage* page1 = [document page: 1];
   PopplerPage* page2 = [document page: 2];
   
   id result1 = [renderer renderPage: page1 scale: 1.0];
   id result2 = [renderer renderPage: page2 scale: 1.0];

   [self assertNotNil: result1];
   [self assertNotNil: result2];
   [self assertFalse: result1 == result2];

   [self assert: [renderer renderPage: page1 scale: 1.0] same: result1];
   [self assert: [renderer renderPage: page2 scale: 1.0] same: result2];
}

- (void) testRenderPageVaryingScale
{
   PopplerPage* page = [document page: 2];
   
   id result1 = [renderer renderPage: page scale: 0.545];
   id result2 = [renderer renderPage: page scale: 0.544];

   [self assertNotNil: result1];
   [self assertNotNil: result2];
   [self assertFalse: result1 == result2];

   [self assert: [renderer renderPage: page scale: 0.545] same: result1];
   [self assert: [renderer renderPage: page scale: 0.544] same: result2];
}

- (void) testRenderPageVaryingSrcBox
{
   PopplerPage* page = [document page: 1];
   
   NSRect rect1 = NSMakeRect(10, 10, 100, 200);
   NSRect rect2 = NSMakeRect(20, 10, 100, 200);
   
   id result1 = [renderer renderPage: page srcBox: rect1 scale: 0.8];
   id result2 = [renderer renderPage: page srcBox: rect2 scale: 0.8];
   
   [self assertNotNil: result1];
   [self assertNotNil: result2];
   [self assertFalse: result1 == result2];
   
   [self assert: [renderer renderPage: page srcBox: rect1 scale: 0.8] same: result1];
   [self assert: [renderer renderPage: page srcBox: rect2 scale: 0.8] same: result2];
}

@end
