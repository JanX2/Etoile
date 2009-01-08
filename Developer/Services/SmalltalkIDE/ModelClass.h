/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <Foundation/Foundation.h>

@class ModelMethod;

@interface ModelClass : NSObject
{
	NSString* name;
	NSString* parent;
	NSString* documentation;
	NSMutableDictionary* categories;
	NSMutableArray* methods;
}

- (id) initWithName: (NSString*) aName;
- (void) setName: (NSString*) aName;
- (NSString*) name;
- (void) setDocumentation: (NSString*) aDocumentation;
- (NSString*) documentation;
- (void) addMethod: (ModelMethod*) aMethod;
- (void) removeMethod: (ModelMethod*) aMethod;
- (NSMutableArray*) methods;
- (void) reloadCategories;
- (void) removeCategory: (NSString*) categoryName;
- (NSMutableArray*) setCategory: (NSString*) name;
- (NSMutableDictionary*) categories;
- (NSMutableArray*) sortedCategories;
- (NSString*) representation;

@end
