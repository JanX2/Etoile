//
//  Method.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "GSDocParser.h"
#import "DocElement.h"


@interface DocMethod : DocSubroutine <GSDocParserDelegate>
{
  BOOL isClassMethod;
  NSMutableArray* selectors;
  NSMutableArray* categories;
  NSString* description;
}

- (void) setIsClassMethod: (BOOL) isTrue;
- (void) addSelector: (NSString*) aSelector;
- (void) addCategory: (NSString*) aCategory;
- (BOOL) isClassMethod;
- (NSString*) content;

@end
