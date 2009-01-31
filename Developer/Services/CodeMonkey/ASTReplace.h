/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#include <AppKit/AppKit.h>

@protocol LKASTVisitor;
@class LKAST;
@class ModelMethod;

@interface ASTReplace : NSObject<LKASTVisitor>
{
	LKAST* oldNode;
	LKAST* newNode;
	BOOL replaced;
}
- (void) setOldNode: (LKAST*) node;
- (void) setNewNode: (LKAST*) node;
- (BOOL) result;
- (LKAST*) visitASTNode: (LKAST*) aNode;
+ (BOOL) replace: (LKAST*) nodeA with: (LKAST*) nodeB on: (LKAST*) target;
@end
