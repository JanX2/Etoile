//
//  PopplerTextSearchTest.h
//  PopplerKit
//
//  Created by Stefan Kleine Stegemann on 8/29/05.
//  Copyright 2005 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PopplerKit/PopplerKit.h>
#import <ObjcUnit/ObjcUnit.h>
#import <MocKit/MockObject.h>


@interface PopplerTextSearchTest : TestCase {
   PopplerDocument* document;
}
@end

// dummy delegate
@interface DummyDelegate : NSObject {
}
- (void) searchWillStart: (PopplerTextSearch*)aSearch;
- (void) search: (PopplerTextSearch*)search didFoundHit: (PopplerTextHit*)hit;
- (void) search: (PopplerTextSearch*)search didCompletePage: (PopplerPage*)page;
- (void) searchDidFinish: (PopplerTextSearch*)aSearch;
@end

// stops the search when it receives the first hit
@interface CancelDelegate : DummyDelegate {
}
@end

// argument rule for page index verification
@interface ArgNextPageIndexRule : NSObject <ArgumentRule> {
   PopplerDocument* document;
   unsigned currentPageIndex;
   unsigned startPageIndex;
}
- (id) initWithStartPage: (unsigned)aStartPageIndex document: (PopplerDocument*)aDocument;
+ (ArgNextPageIndexRule*) ruleWithStartPage: (unsigned)aStartPageIndex document: (PopplerDocument*)aDocument;
@end
