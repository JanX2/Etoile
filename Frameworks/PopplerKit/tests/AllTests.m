//
//  AllTests.m
//  PopplerKit
//
//  Created by Stefan Kleine Stegemann on 7/28/05.
//  Copyright 2005 . All rights reserved.
//

#import "AllTests.h"
#import "PopplerDocumentTest.h"
#import "PopplerPageTest.h"
#import "PopplerTextSearchTest.h"
#import "PopplerRendererTest.h"
#import "PopplerCachingRendererTest.h"

@implementation AllTests

+ (TestSuite*) suite { 
   TestSuite *suite = [TestSuite suiteWithName: @"PopplerKit Tests"]; 

   // Add your tests here ... 
   [suite addTest: [TestSuite suiteWithClass: [PopplerDocumentTest class]]];
   [suite addTest: [TestSuite suiteWithClass: [PopplerPageTest class]]];
   [suite addTest: [TestSuite suiteWithClass: [PopplerTextSearchTest class]]];
   [suite addTest: [TestSuite suiteWithClass: [PopplerRendererTest class]]];
   [suite addTest: [TestSuite suiteWithClass: [PopplerCachingRendererTest class]]];

   return suite; 
}

@end

int main( int argc, const char * argv[]) { 
    TestRunnerMain([AllTests class]); 
    return 0; 
}
