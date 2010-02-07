/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#include <AppKit/AppKit.h>

@class ModelClass;
@class ModelApplication;

@interface IDE : NSObject
{
  NSMutableArray* classes;
  ModelApplication* application;
}
+ (IDE*) default;
- (ModelApplication*) application;
- (NSMutableArray*) classes;
- (void) loadContent: (NSString*) aContent;
- (void) addClass: (NSString*) className;

- (ModelClass*) classForName: (NSString*) aClassName;

- (void) addCategory: (NSString*) categoryName onClass: (NSString*) aClassName;
- (void) addMethod: (NSMutableAttributedString*) code 
	withSignature: (NSString*) signature
	withCategory: (NSString*) categoryName
	onClass: (NSString*) aClassName;
- (void) addClassMethod: (NSMutableAttributedString*) code 
	withSignature: (NSString*) signature
	withCategory: (NSString*) categoryName
	onClass: (NSString*) aClassName;
- (void) addProperty: (NSString*) propertyName onClass: (NSString*) aClassName;
- (NSMutableString*) allClassesContent;
- (void) removeClassAtIndex: (int) row;
- (void) replaceMethod: (NSString*) methodSignature
	withSignature: (NSString*) signature
	andCode: (NSString*) code
	onClass: (NSString*) aClassName;
@end

@interface IDE (COProxy)
- (void) setPersistencyMethodNames: (NSArray *)names;
- (unsigned int) objectVersion;
- (IDE*) _realObject;
@end
