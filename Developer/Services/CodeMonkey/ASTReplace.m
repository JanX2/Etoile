/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>
#import "ASTReplace.h"
#import "ModelClass.h"
#import "ModelMethod.h"

@implementation ASTReplace

+ (BOOL) replace: (LKAST*) nodeA with: (LKAST*) nodeB on: (LKAST*) target
{
	ASTReplace* replace = [ASTReplace new];
	[replace setOldNode: nodeA];
	[replace setNewNode: nodeB];
	[target visitWithVisitor: replace];
	BOOL ret = [replace result];
	[replace release];
	return ret;
}

- (id) init
{
	self = [super init];
	replaced = NO;
	return self;	
}

- (void) dealloc
{
	[oldNode release];
	[newNode release];
	[super dealloc];
}

- (void) setOldNode: (LKAST*) node
{
	[node retain];
	[oldNode release];
	oldNode = node;
}

- (void) setNewNode: (LKAST*) node
{
	[node retain];
	[newNode release];
	newNode = node;
}

- (BOOL) result
{
	return replaced;
}

- (LKAST*) visitASTNode: (LKAST*) aNode
{
	if (aNode == oldNode) {
		replaced = YES;
		return newNode;
	}
	return aNode;
}
@end

