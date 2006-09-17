//
//  PopplerTextSearchTest.m
//  PopplerKit
//
//  Created by Stefan Kleine Stegemann on 8/29/05.
//  Copyright 2005 . All rights reserved.
//

#import "PopplerTextSearchTest.h"
#import "TestSettings.h"

@implementation PopplerTextSearchTest

- (void) setUp
{
   document = [[PopplerDocument alloc] initWithPath: kTestDocument];
}

- (void) tearDown
{
   [document release];
}

- (void) testSearch
{
   PopplerTextSearch* search = [PopplerTextSearch searchWithDocument: document];
   
   NSArray* hits = [search searchFor: @"NEXTSTEP" from: 2];
   [self assertNotNil: hits];
   [self assertTrue: [hits count] > 1 message: @"not enought hits"];
   [self assertFalse: [search running] message: @"search should not be running"];

   id delegate = [MockObject mockForClass: [DummyDelegate class] testCase: self];

   [[[delegate expect: @selector(searchWillStart:)]
      once]
      with: [Arg sameAs: search]];
   
   [[[delegate expect: @selector(search:didFoundHit:)]
      times: [hits count]]
      with: [Arg sameAs: search] with: [Arg isA: [PopplerTextHit class]]];
   
   [[[delegate expect: @selector(search:didCompletePage:)]
      times: [document countPages]]
       with: [Arg sameAs: search]
       with: [ArgNextPageIndexRule ruleWithStartPage: 2 document: document]];

   [[[delegate expect: @selector(searchDidFinish:)]
      once]
      with: [Arg sameAs: search]];
   
   [search searchFor: @"NEXTSTEP" from: 2 delegate: delegate];
   
   [delegate verify];
   [self assertFalse: [search running] message: @"search should not be running"];
}

- (void) testStopSearch
{
   PopplerTextSearch* search = [PopplerTextSearch searchWithDocument: document];
   
   id delegate = [[[CancelDelegate alloc] init] autorelease];
   id mockDelegate = [MockObject mockForClass: [delegate class] testCase: self];
   
   [[[mockDelegate expect: @selector(searchWillStart:)]
      once]
      with: [Arg sameAs: search]];
   
   [[[[mockDelegate expect: @selector(search:didFoundHit:)]
      once]
      with: [Arg sameAs: search] with: [Arg isA: [PopplerTextHit class]]]
      delegate: delegate];
   
   [[[mockDelegate expect: @selector(search:didCompletePage:)]
      never]
       with: [Arg sameAs: search]
       with: [ArgNextPageIndexRule ruleWithStartPage: 2 document: document]];
   
   [[[mockDelegate expect: @selector(searchDidFinish:)]
      once]
      with: [Arg sameAs: search]];
   
   [search searchFor: @"NEXTSTEP" from: 2 delegate: mockDelegate];
   
   [mockDelegate verify];
   [self assertFalse: [search running] message: @"search should not be running"];
}

- (void) testSearchPageRange
{
   PopplerTextSearch* search = [PopplerTextSearch searchWithDocument: document];
   
   NSArray* hits = [search searchFor: @"NEXTSTEP" from: 4 to: 2];
   [self assertNotNil: hits];
   [self assertTrue: [hits count] > 1 message: @"not enought hits"];
   [self assertFalse: [search running] message: @"search should not be running"];
   
   id delegate = [MockObject mockForClass: [DummyDelegate class] testCase: self];
   
   [[[delegate expect: @selector(searchWillStart:)]
      once]
      with: [Arg sameAs: search]];
   
   [[[delegate expect: @selector(search:didFoundHit:)]
      times: [hits count]]
      with: [Arg sameAs: search] with: [Arg isA: [PopplerTextHit class]]];
   
   [[[delegate expect: @selector(search:didCompletePage:)]
      times: ([document countPages] - 4) + 1 + 2]
       with: [Arg sameAs: search]
       with: [ArgNextPageIndexRule ruleWithStartPage: 4 document: document]];
   
   [[[delegate expect: @selector(searchDidFinish:)]
      once]
      with: [Arg sameAs: search]];
   
   [search searchFor: @"NEXTSTEP" from: 4 to: 2 delegate: delegate];
   
   [delegate verify];
   [self assertFalse: [search running] message: @"search should not be running"];
}

@end

/* ----------------------------------------------------- */
/*  class DummyDelegate                                  */
/* ----------------------------------------------------- */

@implementation DummyDelegate
- (void) searchWillStart: (PopplerTextSearch*)aSearch; {}
- (void) search: (PopplerTextSearch*)search didFoundHit: (PopplerTextHit*)hit; {}
- (void) search: (PopplerTextSearch*)search didCompletePage: (PopplerPage*)page; {}
- (void) searchDidFinish: (PopplerTextSearch*)aSearch; {}
@end

/* ----------------------------------------------------- */
/*  class CancelDelegate                                 */
/* ----------------------------------------------------- */

@implementation CancelDelegate

- (void) search: (PopplerTextSearch*)search didFoundHit: (PopplerTextHit*)hit;
{
   [search stop];
}

@end

/* ----------------------------------------------------- */
/*  class ArgNextPageIndexRule                           */
/* ----------------------------------------------------- */

@implementation ArgNextPageIndexRule

- (id) initWithStartPage: (unsigned)aStartPageIndex document: (PopplerDocument*)aDocument;
{
   if (![super init])
      return nil;
   
   startPageIndex = aStartPageIndex;
   currentPageIndex = 0;
   document = aDocument;
   
   return self;
}

+ (ArgNextPageIndexRule*) ruleWithStartPage: (unsigned)aStartPageIndex document: (PopplerDocument*)aDocument;
{
   return [[[self alloc] initWithStartPage: aStartPageIndex document: aDocument] autorelease];
}

- (BOOL) satisfiedForValue: (id)value error: (NSString**)error
{
   unsigned expectedPageIndex = 
      (currentPageIndex != 0 ? [document nextPageIndex: currentPageIndex] : startPageIndex);

   if ([value index] != expectedPageIndex) {
      *error = [NSString stringWithFormat: @"expected page with index %d after %d but got %d", expectedPageIndex, currentPageIndex, [value index]];
      return NO;
   }
   
   currentPageIndex = expectedPageIndex;
   return YES;
}

@end
