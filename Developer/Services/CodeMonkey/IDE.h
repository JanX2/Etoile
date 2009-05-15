/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#include <AppKit/AppKit.h>

@class ModelClass;
@class ModelMethod;

@interface IDE : NSObject
{
  NSMutableArray* classes;
}
+ (IDE*) default;
- (NSMutableArray*) classes;
- (void) loadContent: (NSString*) aContent;
- (void) addClass: (NSString*) className;
- (void) addCategory: (NSString*) categoryName onClass: (ModelClass*) aClass;
- (void) addMethod: (NSMutableAttributedString*) code 
	withSignature: (NSString*) signature
	withCategory: (NSString*) categoryName
	onClass: (ModelClass*) aClass;
- (void) addClassMethod: (NSMutableAttributedString*) code 
	withSignature: (NSString*) signature
	withCategory: (NSString*) categoryName
	onClass: (ModelClass*) aClass;
- (void) addProperty: (NSString*) propertyName onClass: (ModelClass*) aClass;
- (NSMutableString*) allClassesContent;
- (void) replaceMethod: (ModelMethod*) method with: (LKAST*) methodAST onClass: (ModelClass*) aClass;
@end
