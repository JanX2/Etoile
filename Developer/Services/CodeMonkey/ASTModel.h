/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#include <AppKit/AppKit.h>

@protocol LKASTVisitor;
@class LKAST;
@class ModelMethod;

@interface ASTModel : NSObject<LKASTVisitor>
{
	NSMutableDictionary* classes;
	ModelMethod* currentMethod;
}
- (NSMutableDictionary*) classes;
- (LKAST*) visitASTNode: (LKAST*) aNode;
@end
