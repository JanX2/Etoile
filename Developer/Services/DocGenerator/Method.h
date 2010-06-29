//
//  Method.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Method : NSObject {
  BOOL isClassMethod;
  NSMutableArray* selectors;
  NSMutableArray* parameters;
  NSString* returnType;
  NSMutableArray* categories;
  NSString* description;
  
  NSString* rawDescription;
  NSString* filteredDescription;
  NSString* task;
}

- (void) setReturnType: (NSString*) aReturnType;
- (void) setIsClassMethod: (BOOL) isTrue;
- (void) addSelector: (NSString*) aSelector;
- (void) addParameter: (NSString*) aName ofType: (NSString*) aType;
- (void) addCategory: (NSString*) aCategory;
- (void) appendToDescription: (NSString*) aDescription;
- (NSString*) methodRawDescription;
- (void) setFilteredDescription: (NSString*) aDescription;
- (BOOL) isClassMethod;
- (NSString*) content;
- (NSString*) task;
- (void) setTask: (NSString*) aTask;

@end
