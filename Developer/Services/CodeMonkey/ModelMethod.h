/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <Foundation/Foundation.h>

@class ModelClass;

@interface ModelMethod : NSObject
{
	ModelClass* class;
	NSString* signature;
	NSString* documentation;
	NSString* code;
	NSMutableString* content;
	NSString* category;
}

- (void) setClass: (ModelClass*) aClass;
- (ModelClass*) class;
- (void) setSignature: (NSString*) aSignature;
- (NSString*) signature;
- (void) setDocumentation: (NSString*) aDocumentation;
- (NSString*) documentation;
- (void) setCode: (NSString*) aCode;
- (NSString*) code;
- (void) setCategory: (NSString*) aCategory;
- (NSString*) category;
- (NSString*) representation;

@end
