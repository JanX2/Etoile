/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <Foundation/Foundation.h>

@class ModelMethod;
@class LKSubclass;

@interface ModelClass : NSObject
{
	NSString* name;
	NSString* parent;
	NSMutableAttributedString* documentation;
	NSMutableDictionary* categories;
	NSMutableArray* methods;
	NSMutableArray* properties;
	LKSubclass* ast;
}

- (id) initWithName: (NSString*) aName;
- (void) setAST: (LKSubclass*) aClassAST;
- (LKSubclass*) ast;
- (void) generateAST;
- (void) setName: (NSString*) aName;
- (NSString*) name;
- (void) setupDocumentation;
- (void) setDocumentation: (NSMutableAttributedString*) aDocumentation;
- (NSMutableAttributedString*) documentation;
- (void) addMethod: (ModelMethod*) aMethod;
- (void) removeMethod: (ModelMethod*) aMethod;
- (void) addProperty: (NSString*) aProperty;
- (NSMutableArray*) properties;
- (NSMutableArray*) methods;
- (void) reloadCategories;
- (void) removeCategory: (NSString*) categoryName;
- (NSMutableArray*) setCategory: (NSString*) name;
- (NSMutableDictionary*) categories;
- (NSMutableArray*) sortedCategories;
- (NSString*) representation;
- (NSString*) dynamicRepresentation;
- (BOOL) hasMethodWithSignature: (NSString*) aSignature;
- (ModelMethod*) methodWithSignature: (NSString*) aSignature;

@end
